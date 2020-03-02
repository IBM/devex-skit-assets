# Developer Experience Starter Kit Assets

This repository provides assets for deploying and monitoring [published Developer Experience starter kits](https://cloud.ibm.com/developer/appservice/starter-kits). Some of the assets available in this repositor include:

* `deployment-assets`: These static deployment assets are used to deploy starter kit apps to Cloud Foundry environments and Kubernetes clusters (where applicable). These assets are written for use within internal IBM infrastructure resources, but they can also be used by other developers as a reference for creating their own deployment assets for apps based on starter kits.
* `scripts`: Scripts in this directory simplify common build, deploy, and verification tasks.

These assets are written primarily for the [starter kit monitoring toolchain](https://github.com/IBM/devex-skit-monitor-toolchain). This toolchain provides pipelines that continuously monitor the starter kit repository for changes and verifies that the updated application code runs successfully in all supported deployment targets. Both the toolchain and the assets in this repository can be used as-is or as starting points for creating custom monitoring pipelines.
