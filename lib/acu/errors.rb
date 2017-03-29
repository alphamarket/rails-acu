module ACU

  class AccessDenied < StandardError
  end

  class UncheckedPermissions < StandardError
  end

  class InvalidSyntax < StandardError
  end

  class AmbiguousRule < StandardError
  end

  class InvalidData < StandardError
  end

  class MissingData < InvalidData
  end

  class MissingUser < InvalidData
  end

  class MissingAction < InvalidData
  end

  class MissingController < InvalidData
  end

  class MissingNamespace < InvalidData
  end

end
