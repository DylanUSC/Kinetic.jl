# ============================================================
# Abstract Types
# ============================================================


export AbstractVelocitySpace,
    AbstractPhysicalSpace,
    AbstractSetup,
    AbstractProperty,
    AbstractCondition,
    AbstractSolverSet,
    AbstractControlVolume,
    AbstractControlVolume1D,
    AbstractInterface,
    AbstractInterface1D,
    AbstractSolution,
    AbstractSolution1D,
    AbstractFlux,
    AbstractFlux1D


abstract type AbstractPhysicalSpace end
abstract type AbstractVelocitySpace end
abstract type AbstractSetup end
abstract type AbstractProperty end
abstract type AbstractCondition end
abstract type AbstractSolverSet end

abstract type AbstractControlVolume end
abstract type AbstractInterface end
abstract type AbstractControlVolume1D <: AbstractControlVolume end
abstract type AbstractInterface1D <: AbstractInterface end

abstract type AbstractSolution end
abstract type AbstractFlux end
abstract type AbstractSolution1D <: AbstractSolution end
abstract type AbstractFlux1D <: AbstractFlux end
