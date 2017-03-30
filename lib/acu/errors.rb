module Acu
  module Errors

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

    class MissingEntity < MissingData
    end

    class MissingUser < MissingData
    end

    class MissingAction < MissingData
    end

    class MissingController < MissingData
    end

    class MissingNamespace < MissingData
    end
  end
end
