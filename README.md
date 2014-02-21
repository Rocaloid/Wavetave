Wavetave
========

Audio signal processing utility sandbox in octave language.

The aim of Wavetave is to test and design algorithms for Rocaloid.

* Wavetave is specifically written for Octave but **not matlab**.

* Depends on `gnuplot`.

###Reference

* Serra, X. 1989. "A System for Sound Analysis/Transformation/Synthesis based on a Deterministic plus Stochastic Decomposition" Ph.D. Thesis. Stanford University.

* Bonada, Jordi, et al. "Singing voice synthesis combining excitation plus resonance and sinusoidal plus residual models." Proceedings of International Computer Music Conference. 2001.

* Sanjaume, Jordi Bonada. Voice processing and synthesis by performance sampling and spectral models. Diss. Universitat Pompeu Fabra, 2008.

---

The main component of Wavetave is a Spectrum Visualizer, located at `src/SpectrumVisualizer.m`

To get it running on your computer:

`$ cd src`

`$ octave`

`octave:1> SpectrumVisualizer`

You can configure the plugins by modifying the source, as described in `SpectrumVisualizer.m`

---

`MinCVE` is an experimental and incomplete version of the upcoming `CVE3.5`. It aims at proving the feasibility of `CVE3.5`.

