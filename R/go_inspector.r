
# Checks if a Java object is null
is_java_object_null <- function(pointer) {
    a <- attributes(pointer)
    attributes(pointer) <- NULL
    out <- identical(pointer, new("externalptr"))
    attributes(pointer) <- a
    return(out)
}

# Reads the GO ontology tree
read_go_ontology <- function() {
    if (!exists("go_tree") || is_java_object_null(go_tree@ontology@jobj)) {
        # detach('package:ontoCAT', unload=TRUE) detach('package:rJava', unload=TRUE) Reads whole Gene ONtology tree
        options(java.parameters = "-Xms8G")
        options(java.parameters = "-Xmx8G")
        # .jinit()

        # .jcall(.jnew('java/lang/Runtime'), 'J', 'maxMemory') go_tree <- getOntology('http://purl.obolibrary.org/obo/go/go-basic.obo')
        go_tree <<- OntoCAT::getOntology("http://purl.obolibrary.org/obo/go.owl")
    }

    go_tree
}

# From the original terms list keeps only the most specific terms.  All terms having any of its descendants included in the list is removed.
get_most_specific_terms <- function(terms_list) {
    go_tree <- read_go_ontology()

    # Parses Java object and retrieves the GO id
    get_term_accession <- function(term) {
        gsub("_", ":", gsub(",.*", "", gsub(".*termAccession = ", "", term@term$toString())))
    }

    # Retrieves all children for a given GO term and removes those children not being associated to any gene in our gene list.
    get_children <- function(object, term_id, associated_terms) {
        children <- sapply(OntoCAT::getAllTermChildrenById(object = object, id = term_id), get_term_accession)
        children[children %in% associated_terms]
    }

    # Keeps only the most specific GO terms, that is those not having children in our list
    terms_and_children <- list(terms = terms_list, children = lapply(terms_list, get_children, object = go_tree, associated_terms = terms_list))
    most_specific_terms <- terms_and_children$terms[unlist(lapply(terms_and_children$children, function(children) {
        length(children) == 0
    }))]

    most_specific_terms
}
