#' Make metadata template ready for data portal
#'
#' @param type A string.
#' @param name A string.
#' @param description A string
#' @param conditions_of_access A string
#' @param url A string
#' @param same_as A string
#' @param identifier A string
#' @param license A string
#' @param citation A string
#' @param measurement_technique A string
#' @param temporal_coverage A string
#' @param creator A string
#' @param variable_info A string
#' @param distribution A string
#' @returns A json string.
#' @export
make_metadata_template = function(type="Dataset", name="", description="", conditions_of_access="", url="", same_as="", identifier="", license="", citation="", measurement_technique = "", temporal_coverage = "", creator = "", variable_info = "", distribution = "") {

  result = jsonlite::fromJSON(paste0('{
"@context": {
    "@vocab": "https://schema.org/",
    "qudt": "http://qudt.org/schema/qudt/",
    "xsd": "http://www.w3.org/2001/XMLSchema#"
  },
  "@type": "', type, '",
  "name": "', name, '",
  "description": "', description, '",
  "conditionsOfAccess": "', conditions_of_access, '",
  "url": "', url, '",
  "sameAs": "', same_as, '",
  "identifier": "', identifier, '",
  "license": "', license, '",
  "citation": [
    "', citation, '"
  ],
  "creator": [],
"variableMeasured": [],
"measurementTechnique": "', measurement_technique, '",
  "temporalCoverage": "', temporal_coverage, '",
  "distribution": []
}'))

  result$creator = creator
  result$variableMeasured = variable_info
  result$distribution = distribution

  return(jsonlite::toJSON(result))
}
