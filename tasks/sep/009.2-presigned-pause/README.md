# Superchain Presigned Pause

Status: SIGNED

See [../../../PRESIGNED-PAUSE.md](../../../PRESIGNED-PAUSE.md) for the playbook.

## Objective

In [this Sepolia transaction](https://sepolia.etherscan.io/tx/0x3d2b9d3e6aaf9f436f05d47c7ae547a3202132ae927966d8fc95c6277d4246b0), we removed the `DeputyGuardianModule` in preparation for setting up the 1 of 1 Guardian Safe.
This invalidated the presigned pauses from [008-presigned-pause](../008-presigned-pause/README.md).
