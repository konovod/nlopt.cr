module NLopt
  enum Algorithm
    GnDirect                = 0
    GnDirectL
    GnDirectLRand
    GnDirectNoscal
    GnDirectLNoscal
    GnDirectLRandNoscal
    GnOrigDirect
    GnOrigDirectL
    GdStogo
    GdStogoRand
    LdLbfgs
    LnPraxis
    LdVaR1
    LdVaR2
    LdTnewton
    LdTnewtonRestart
    LdTnewtonPrecond
    LdTnewtonPrecondRestart
    GnCrS2Lm
    GnMlsl
    GdMlsl
    GnMlslLds
    GdMlslLds
    LdMma
    LnCobyla
    LnNewuoa
    LnNewuoaBound
    LnNeldermead
    LnSbplx
    LnAuglag
    LdAuglag
    LnAuglagEq
    LdAuglagEq
    LnBobyqa
    GnIsres
    Auglag
    AuglagEq
    GMlsl
    GMlslLds
    LdSlsqp
    LdCcsaq
    GnEsch
    GnAgs
  end

  enum Result
    Failure         = -1
    InvalidArgs     = -2
    OutOfMemory     = -3
    RoundoffLimited = -4
    ForcedStop      = -5
    Success         =  1
    StopvalReached  =  2
    FtolReached     =  3
    XtolReached     =  4
    MaxevalReached  =  5
    MaxtimeReached  =  6
  end
end

@[Link("nlopt")]
lib LibNLopt
  alias PtrdiffT = LibC::SizeT
  type Opt = Void*
  alias Func = (LibC::UInt, LibC::Double*, LibC::Double*, Void* -> LibC::Double)
  alias Precond = (LibC::UInt, LibC::Double*, LibC::Double*, LibC::Double*, Void* -> Void)
  alias Mfunc = (LibC::UInt, LibC::Double*, LibC::UInt, LibC::Double*, LibC::Double*, Void* -> Void)
  alias Munge = (Void* -> Void*)
  alias Munge2 = (Void*, Void* -> Void*)
  alias FuncOld = (LibC::Int, LibC::Double*, LibC::Double*, Void* -> LibC::Double)

  fun algorithm_name = nlopt_algorithm_name(a : NLopt::Algorithm) : LibC::Char*
  fun algorithm_to_string = nlopt_algorithm_to_string(algorithm : NLopt::Algorithm) : LibC::Char*
  fun algorithm_from_string = nlopt_algorithm_from_string(name : LibC::Char*) : NLopt::Algorithm
  fun result_to_string = nlopt_result_to_string(result : NLopt::Result) : LibC::Char*
  fun result_from_string = nlopt_result_from_string(name : LibC::Char*) : NLopt::Result

  fun srand = nlopt_srand(seed : LibC::ULong)
  fun srand_time = nlopt_srand_time
  fun version = nlopt_version(major : LibC::Int*, minor : LibC::Int*, bugfix : LibC::Int*)
  fun create = nlopt_create(algorithm : NLopt::Algorithm, n : LibC::UInt) : Opt
  fun destroy = nlopt_destroy(opt : Opt)
  fun copy = nlopt_copy(opt : Opt) : Opt
  fun get_algorithm = nlopt_get_algorithm(opt : Opt) : NLopt::Algorithm
  fun get_dimension = nlopt_get_dimension(opt : Opt) : LibC::UInt
  fun set_min_objective = nlopt_set_min_objective(opt : Opt, f : Func, f_data : Void*) : NLopt::Result
  fun set_max_objective = nlopt_set_max_objective(opt : Opt, f : Func, f_data : Void*) : NLopt::Result
  fun set_precond_min_objective = nlopt_set_precond_min_objective(opt : Opt, f : Func, pre : Precond, f_data : Void*) : NLopt::Result
  fun set_precond_max_objective = nlopt_set_precond_max_objective(opt : Opt, f : Func, pre : Precond, f_data : Void*) : NLopt::Result

  fun optimize = nlopt_optimize(opt : Opt, x : LibC::Double*, opt_f : LibC::Double*) : NLopt::Result
  fun get_errmsg = nlopt_get_errmsg(opt : Opt) : LibC::Char*

  fun set_param = nlopt_set_param(opt : Opt, name : LibC::Char*, val : LibC::Double)
  fun get_param = nlopt_get_param(opt : Opt, name : LibC::Char*, defaultval : LibC::Double) : LibC::Double
  fun has_param = nlopt_has_param(opt : Opt, name : LibC::Char*) : LibC::Int
  fun num_params = nlopt_num_params(opt : Opt) : LibC::UInt
  fun nth_param = nlopt_nth_param(opt : Opt, n : LibC::UInt) : LibC::Char*

  fun set_lower_bounds = nlopt_set_lower_bounds(opt : Opt, lb : LibC::Double*) : NLopt::Result
  fun set_lower_bounds1 = nlopt_set_lower_bounds1(opt : Opt, lb : LibC::Double) : NLopt::Result
  fun set_lower_bound = nlopt_set_lower_bound(opt : Opt, i : LibC::Int, lb : LibC::Double*) : NLopt::Result
  fun get_lower_bounds = nlopt_get_lower_bounds(opt : Opt, lb : LibC::Double*) : NLopt::Result
  fun set_upper_bounds = nlopt_set_upper_bounds(opt : Opt, ub : LibC::Double*) : NLopt::Result
  fun set_upper_bounds1 = nlopt_set_upper_bounds1(opt : Opt, ub : LibC::Double) : NLopt::Result
  fun set_upper_bound = nlopt_set_upper_bound(opt : Opt, i : LibC::Int, lb : LibC::Double*) : NLopt::Result
  fun get_upper_bounds = nlopt_get_upper_bounds(opt : Opt, ub : LibC::Double*) : NLopt::Result

  fun remove_inequality_constraints = nlopt_remove_inequality_constraints(opt : Opt) : NLopt::Result
  fun add_inequality_constraint = nlopt_add_inequality_constraint(opt : Opt, fc : Func, fc_data : Void*, tol : LibC::Double) : NLopt::Result
  fun add_precond_inequality_constraint = nlopt_add_precond_inequality_constraint(opt : Opt, fc : Func, pre : Precond, fc_data : Void*, tol : LibC::Double) : NLopt::Result
  fun add_inequality_mconstraint = nlopt_add_inequality_mconstraint(opt : Opt, m : LibC::UInt, fc : Mfunc, fc_data : Void*, tol : LibC::Double*) : NLopt::Result
  fun remove_equality_constraints = nlopt_remove_equality_constraints(opt : Opt) : NLopt::Result
  fun add_equality_constraint = nlopt_add_equality_constraint(opt : Opt, h : Func, h_data : Void*, tol : LibC::Double) : NLopt::Result
  fun add_precond_equality_constraint = nlopt_add_precond_equality_constraint(opt : Opt, h : Func, pre : Precond, h_data : Void*, tol : LibC::Double) : NLopt::Result
  fun add_equality_mconstraint = nlopt_add_equality_mconstraint(opt : Opt, m : LibC::UInt, h : Mfunc, h_data : Void*, tol : LibC::Double*) : NLopt::Result

  fun set_stopval = nlopt_set_stopval(opt : Opt, stopval : LibC::Double) : NLopt::Result
  fun get_stopval = nlopt_get_stopval(opt : Opt) : LibC::Double
  fun set_ftol_rel = nlopt_set_ftol_rel(opt : Opt, tol : LibC::Double) : NLopt::Result
  fun get_ftol_rel = nlopt_get_ftol_rel(opt : Opt) : LibC::Double
  fun set_ftol_abs = nlopt_set_ftol_abs(opt : Opt, tol : LibC::Double) : NLopt::Result
  fun get_ftol_abs = nlopt_get_ftol_abs(opt : Opt) : LibC::Double
  fun set_xtol_rel = nlopt_set_xtol_rel(opt : Opt, tol : LibC::Double) : NLopt::Result
  fun get_xtol_rel = nlopt_get_xtol_rel(opt : Opt) : LibC::Double
  fun set_xtol_abs1 = nlopt_set_xtol_abs1(opt : Opt, tol : LibC::Double) : NLopt::Result
  fun set_xtol_abs = nlopt_set_xtol_abs(opt : Opt, tol : LibC::Double*) : NLopt::Result
  fun get_xtol_abs = nlopt_get_xtol_abs(opt : Opt, tol : LibC::Double*) : NLopt::Result
  fun set_x_weights1 = nlopt_set_x_weights1(opt : Opt, w : LibC::Double) : NLopt::Result
  fun set_x_weights = nlopt_set_x_weights(opt : Opt, w : LibC::Double*) : NLopt::Result
  fun get_x_weights = nlopt_get_x_weights(opt : Opt, w : LibC::Double*) : NLopt::Result
  fun set_maxeval = nlopt_set_maxeval(opt : Opt, maxeval : LibC::Int) : NLopt::Result
  fun get_maxeval = nlopt_get_maxeval(opt : Opt) : LibC::Int
  fun get_numevals = nlopt_get_numevals(opt : Opt) : LibC::Int
  fun set_maxtime = nlopt_set_maxtime(opt : Opt, maxtime : LibC::Double) : NLopt::Result
  fun get_maxtime = nlopt_get_maxtime(opt : Opt) : LibC::Double
  fun force_stop = nlopt_force_stop(opt : Opt) : NLopt::Result
  fun set_force_stop = nlopt_set_force_stop(opt : Opt, val : LibC::Int) : NLopt::Result
  fun get_force_stop = nlopt_get_force_stop(opt : Opt) : LibC::Int
  fun set_local_optimizer = nlopt_set_local_optimizer(opt : Opt, local_opt : Opt) : NLopt::Result
  fun set_population = nlopt_set_population(opt : Opt, pop : LibC::UInt) : NLopt::Result
  fun get_population = nlopt_get_population(opt : Opt) : LibC::UInt
  fun set_vector_storage = nlopt_set_vector_storage(opt : Opt, dim : LibC::UInt) : NLopt::Result
  fun get_vector_storage = nlopt_get_vector_storage(opt : Opt) : LibC::UInt
  fun set_default_initial_step = nlopt_set_default_initial_step(opt : Opt, x : LibC::Double*) : NLopt::Result
  fun set_initial_step = nlopt_set_initial_step(opt : Opt, dx : LibC::Double*) : NLopt::Result
  fun set_initial_step1 = nlopt_set_initial_step1(opt : Opt, dx : LibC::Double) : NLopt::Result
  fun get_initial_step = nlopt_get_initial_step(opt : Opt, x : LibC::Double*, dx : LibC::Double*) : NLopt::Result

  # Unused API

  fun set_munge = nlopt_set_munge(opt : Opt, munge_on_destroy : Munge, munge_on_copy : Munge)
  fun munge_data = nlopt_munge_data(opt : Opt, munge : Munge2, data : Void*)

  # Deprecated API

  fun minimize = nlopt_minimize(algorithm : NLopt::Algorithm, n : LibC::Int, f : FuncOld, f_data : Void*, lb : LibC::Double*, ub : LibC::Double*, x : LibC::Double*, minf : LibC::Double*, minf_max : LibC::Double, ftol_rel : LibC::Double, ftol_abs : LibC::Double, xtol_rel : LibC::Double, xtol_abs : LibC::Double*, maxeval : LibC::Int, maxtime : LibC::Double) : NLopt::Result
  fun minimize_constrained = nlopt_minimize_constrained(algorithm : NLopt::Algorithm, n : LibC::Int, f : FuncOld, f_data : Void*, m : LibC::Int, fc : FuncOld, fc_data : Void*, fc_datum_size : PtrdiffT, lb : LibC::Double*, ub : LibC::Double*, x : LibC::Double*, minf : LibC::Double*, minf_max : LibC::Double, ftol_rel : LibC::Double, ftol_abs : LibC::Double, xtol_rel : LibC::Double, xtol_abs : LibC::Double*, maxeval : LibC::Int, maxtime : LibC::Double) : NLopt::Result
  fun minimize_econstrained = nlopt_minimize_econstrained(algorithm : NLopt::Algorithm, n : LibC::Int, f : FuncOld, f_data : Void*, m : LibC::Int, fc : FuncOld, fc_data : Void*, fc_datum_size : PtrdiffT, p : LibC::Int, h : FuncOld, h_data : Void*, h_datum_size : PtrdiffT, lb : LibC::Double*, ub : LibC::Double*, x : LibC::Double*, minf : LibC::Double*, minf_max : LibC::Double, ftol_rel : LibC::Double, ftol_abs : LibC::Double, xtol_rel : LibC::Double, xtol_abs : LibC::Double*, htol_rel : LibC::Double, htol_abs : LibC::Double, maxeval : LibC::Int, maxtime : LibC::Double) : NLopt::Result

  fun get_local_search_algorithm = nlopt_get_local_search_algorithm(deriv : NLopt::Algorithm*, nonderiv : NLopt::Algorithm*, maxeval : LibC::Int*)
  fun set_local_search_algorithm = nlopt_set_local_search_algorithm(deriv : NLopt::Algorithm, nonderiv : NLopt::Algorithm, maxeval : LibC::Int)
  fun get_stochastic_population = nlopt_get_stochastic_population : LibC::Int
  fun set_stochastic_population = nlopt_set_stochastic_population(pop : LibC::Int)
end
