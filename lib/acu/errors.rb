module Acu

  class AccessDenied < StandardError
  end

  class UncheckedPermissions < StandardError
  end

  class InvalidSyntax < StandardError
  end

  class AmbiguousRule < StandardError
  end

  class MissingUser < StandardError
  end

  class MissingAction < StandardError
  end

end
