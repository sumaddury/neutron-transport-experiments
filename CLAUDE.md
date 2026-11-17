# Agent instructions

This repo contains some experimental work related to stellarator blanket optimization using OpenMC. The main purpose is to collect data on derivative experiments and improve simulations in openmc-derivative-testing.

Items
- The build environment builds the complex dependencies for the openmc-diffgeom package, which is a fork of OpenMC that computes forward derivatives of neutrons during simulation.
- openmc-derivative-testing contains some experiemnts built on top of openmc-diffgeom. 
- openmc-notebooks contains some basic examples for the base openmc package


Background:
- To understand the context of the problem, please read the background section of papers/Surrogate-Assisted,_Gradient-B.pdf.
- Please read papers/NoteOnForwardAndReplayPathDifferentiation.pdf, papers/Differentiable Neutron Transport.pdf, and select parts of the openmc-diffgeom source code to understand the forward gradient step.


Do's/Don'ts:
- Do not expect commit logs and notes to provide a sufficient explanation of the background and current state of projects.
- Do not get confused by the large amounts of openmc-diffgeom source code
- Do read the background papers to get a single consistent view of what is going on