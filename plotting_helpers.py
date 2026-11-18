"""Parse surface_mesh batch traces (``python -m surface_mesh.cli.batch_trace``) for notebooks.

A trace directory holds ``sample.npz`` and ``settings.json``. Unlike the CSG
traces in data/batch-convergence (running means), the per-batch arrays here
are each batch's own value; ``running_mean_se`` converts them.

    from surface_mesh_batches import load_mesh_trace
    trace = load_mesh_trace("data/surface-mesh-batches/smoke_box_r2")
    trace.df.head()
"""

from dataclasses import dataclass
import json
from pathlib import Path

import numpy as np
import pandas as pd


@dataclass
class MeshBatchTrace:
    settings: dict            # run settings (model_variant, particles, batches, seed, ...)
    coordinates: np.ndarray   # (N, 3) vertex positions, cm, mesh-local frame
    faces: np.ndarray         # (F, 3) vertex indices per triangle, outward-oriented
    flux: np.ndarray          # (B,) tally value of each batch
    gradient: np.ndarray      # (B, N, 3) dT/dx_k of each batch (vertex, xyz)
    dJ: np.ndarray            # (B, N, 3) Jacobian term of gradient
    datt: np.ndarray          # (B, N, 3) attenuation term; gradient = dJ + datt
    df: pd.DataFrame          # per batch: batch, T_batch, T, T_std (running mean and its SE)

@dataclass
class BatchedNpz:
    names: list[str]
    metadata: dict
    df: pd.DataFrame

def load_batched(path: str) -> BatchedNpz:
    d = np.load(path)
    
    names = list(d["parameter_names"])
    metadata = json.loads(str(d["metadata"]))
    df = pd.DataFrame({
        "batch" : d["batch"],
        "T" : d["tally_mean"],
        "T_std" : d["tally_std_dev"]
    })
    for key in ("gradient", "dJ", "datt"):
        for i, name in enumerate(names):
            df[f"{key}_{name}"] = d[key][:, i]
        
    return BatchedNpz(names, metadata, df)

def running_mean_se(values):
    """Running mean and standard error of the mean over axis 0 (SE is NaN at batch 1)."""
    values = np.asarray(values, dtype=float)
    b = np.arange(1, len(values) + 1).reshape(-1, *([1] * (values.ndim - 1)))
    mean = np.cumsum(values, axis=0) / b
    with np.errstate(invalid="ignore", divide="ignore"):
        variance = (np.cumsum(values ** 2, axis=0) - b * mean ** 2) / (b - 1)
        se = np.sqrt(np.maximum(variance, 0) / b)
    se[0] = np.nan
    return mean, se


def load_mesh_trace(directory) -> MeshBatchTrace:
    directory = Path(directory)
    settings = json.loads((directory / "settings.json").read_text())
    with np.load(directory / "sample.npz") as d:
        flux = d["batch_flux"]
        T, T_std = running_mean_se(flux)
        df = pd.DataFrame({"batch": np.arange(1, len(flux) + 1), "T_batch": flux,
                           "T": T, "T_std": T_std})
        return MeshBatchTrace(settings, d["coordinates"], d["faces"], flux,
                              d["batch_gradient"], d["batch_dJ"], d["batch_datt"], df)


def vertex_normals(coordinates, faces):
    """Area-weighted outward unit normal at each vertex, (N, 3)."""
    x = np.asarray(coordinates)
    face_normals = np.cross(x[faces[:, 1]] - x[faces[:, 0]], x[faces[:, 2]] - x[faces[:, 0]])
    normals = np.zeros_like(x, dtype=float)
    for corner in range(3):
        np.add.at(normals, faces[:, corner], face_normals)
    return normals / np.linalg.norm(normals, axis=1, keepdims=True)


def normal_components(trace: MeshBatchTrace, values=None):
    """Per-batch derivative along each vertex normal, (B, N). Defaults to trace.gradient.

    Summing over vertices gives the derivative for moving every vertex outward
    by the same distance (dT/dr for a sphere mesh).
    """
    values = trace.gradient if values is None else values
    return np.einsum("bkc,kc->bk", values, vertex_normals(trace.coordinates, trace.faces))


def total_relative_noise(batch_gradient):
    """Debiased total relative noise rho of the batch-mean gradient (inf while noise dominates).

    rho = sqrt(sum_i SE_i^2) / ||g||, with ||g||^2 estimated as ||mean||^2 - sum_i SE_i^2.
    """
    g = np.asarray(batch_gradient, dtype=float).reshape(len(batch_gradient), -1)
    noise2 = g.var(axis=0, ddof=1).sum() / len(g)
    signal2 = np.sum(g.mean(axis=0) ** 2) - noise2
    return float(np.sqrt(noise2 / signal2)) if signal2 > 0 else np.inf


@dataclass
class OptimizationRun:
    name: str
    settings: dict             # int_run settings (particles, batches, adaptive_batches, ...)
    evaluations: pd.DataFrame  # one row per transport evaluation (see load_optimization_run)
    trials: pd.DataFrame       # one row per optimizer update


def _simulation_seconds(log_path):
    """OpenMC's 'Total time in simulation' from a transport.log, or NaN."""
    for line in Path(log_path).read_text().splitlines():
        if "Total time in simulation" in line:
            return float(line.split("=")[1].split()[0])
    return np.nan


def load_optimization_run(directory, name=None) -> OptimizationRun:
    """Parse a surface_mesh optimizer output directory (``python -m surface_mesh``).

    ``evaluations`` columns: evaluation, iteration (0 = initial mesh), mesh, T, T_std,
    T_rse, batches, particles, histories, cumulative_histories, rho (total relative
    noise of the gradient; needs record_batches), sim_seconds (OpenMC transport time),
    adaptive_status (last sizer decision, adaptive runs only).
    """
    directory = Path(directory)
    history = json.loads((directory / "history.json").read_text())
    trials = pd.DataFrame([{key: t.get(key) for key in (
        "iteration", "status", "gradient_evaluation", "candidate_evaluation",
        "predicted_change", "observed_tally_change", "difference_std_dev")}
        for t in history["trials"]])
    iteration_of = {0: 0}
    if len(trials):
        iteration_of.update(trials.dropna(subset=["candidate_evaluation"]).astype(
            {"candidate_evaluation": int}).set_index("candidate_evaluation")["iteration"].to_dict())
    rows = []
    for e in history["evaluations"]:
        if e.get("status") != "complete":
            continue
        folder = directory / e["directory"]
        with np.load(folder / "sample.npz") as s:
            rho = total_relative_noise(s["batch_gradient"]) if "batch_gradient" in s.files else np.nan
            status = str(s["adaptive_status"][-1]) if "adaptive_status" in s.files else None
        rows.append(dict(evaluation=e["index"], iteration=iteration_of.get(e["index"]),
                         mesh=e["mesh"], T=e["tally_mean"], T_std=e["tally_std_dev"],
                         batches=e["num_realizations"], particles=e["particles"], rho=rho,
                         sim_seconds=_simulation_seconds(folder / "transport.log"),
                         adaptive_status=status))
    evaluations = pd.DataFrame(rows)
    evaluations["T_rse"] = evaluations["T_std"] / evaluations["T"].abs()
    evaluations["histories"] = evaluations["batches"] * evaluations["particles"]
    evaluations["cumulative_histories"] = evaluations["histories"].cumsum()
    return OptimizationRun(name or directory.name, history["int_run"], evaluations, trials)
