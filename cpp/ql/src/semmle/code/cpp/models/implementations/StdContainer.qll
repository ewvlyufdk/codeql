/**
 * Provides models for C++ containers `std::array`, `std::vector`, `std::deque`, `std::list` and `std::forward_list`.
 */

import semmle.code.cpp.models.interfaces.Taint

/**
 * Additional model for standard container constructors that reference the
 * value type of the container (that is, the `T` in `std::vector<T>`).  For
 * example the fill constructor:
 * ```
 * std::vector<std::string> v(100, potentially_tainted_string);
 * ```
 */
class StdSequenceContainerConstructor extends Constructor, TaintFunction {
  StdSequenceContainerConstructor() {
    this.getDeclaringType().hasQualifiedName("std", ["vector", "deque", "list", "forward_list"])
  }

  /**
   * Gets the index of a parameter to this function that is a reference to the
   * value type of the container.
   */
  int getAValueTypeParameterIndex() {
    getParameter(result).getUnspecifiedType().(ReferenceType).getBaseType() =
      getDeclaringType().getTemplateArgument(0) // i.e. the `T` of this `std::vector<T>`
  }

  override predicate hasTaintFlow(FunctionInput input, FunctionOutput output) {
    // taint flow from any parameter of the value type to the returned object
    input.isParameterDeref(getAValueTypeParameterIndex()) and
    output.isReturnValue() // TODO: this should be `isQualifierObject` by our current definitions, but that flow is not yet supported.
  }
}

/**
 * The standard container functions `push_back` and `push_front`.
 */
class StdSequenceContainerPush extends TaintFunction {
  StdSequenceContainerPush() {
    this.hasQualifiedName("std", "vector", "push_back") or
    this.hasQualifiedName("std", "deque", ["push_back", "push_front"]) or
    this.hasQualifiedName("std", "list", ["push_back", "push_front"]) or
    this.hasQualifiedName("std", "forward_list", "push_front")
  }

  override predicate hasTaintFlow(FunctionInput input, FunctionOutput output) {
    // flow from parameter to qualifier
    input.isParameterDeref(0) and
    output.isQualifierObject()
  }
}

/**
 * The standard container functions `front` and `back`.
 */
class StdSequenceContainerFrontBack extends TaintFunction {
  StdSequenceContainerFrontBack() {
    this.hasQualifiedName("std", "array", ["front", "back"]) or
    this.hasQualifiedName("std", "vector", ["front", "back"]) or
    this.hasQualifiedName("std", "deque", ["front", "back"]) or
    this.hasQualifiedName("std", "list", ["front", "back"]) or
    this.hasQualifiedName("std", "forward_list", "front")
  }

  override predicate hasTaintFlow(FunctionInput input, FunctionOutput output) {
    // flow from object to returned reference
    input.isQualifierObject() and
    output.isReturnValueDeref()
  }
}

/**
 * The standard container `swap` functions.
 */
class StdSequenceContainerSwap extends TaintFunction {
  StdSequenceContainerSwap() {
    this.hasQualifiedName("std", ["array", "vector", "deque", "list", "forward_list"], "swap")
  }

  override predicate hasTaintFlow(FunctionInput input, FunctionOutput output) {
    // container1.swap(container2)
    input.isQualifierObject() and
    output.isParameterDeref(0)
    or
    input.isParameterDeref(0) and
    output.isQualifierObject()
  }
}

/**
 * The standard container functions `at` and `operator[]`.
 */
class StdSequenceContainerAt extends TaintFunction {
  StdSequenceContainerAt() {
    this.hasQualifiedName("std", ["vector", "array", "deque"], ["at", "operator[]"])
  }

  override predicate hasTaintFlow(FunctionInput input, FunctionOutput output) {
    // flow from qualifier to referenced return value
    input.isQualifierObject() and
    output.isReturnValueDeref()
    or
    // reverse flow from returned reference to the qualifier
    input.isReturnValueDeref() and
    output.isQualifierObject()
  }
}
