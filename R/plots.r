# library(treemap) library(gridExtra) library(ggplot2) library(scales) library(grid) library(VennDiagram) library(ggbiplot) library(gplots) library(Cairo)


# COlors to use in plots
red500 <- rgb(as.integer(as.hexmode("f4")), as.integer(as.hexmode("43")), as.integer(as.hexmode("36")), maxColorValue = 255)
green500 <- rgb(as.integer(as.hexmode("4c")), as.integer(as.hexmode("af")), as.integer(as.hexmode("50")), maxColorValue = 255)
indigo500 <- rgb(as.integer(as.hexmode("3f")), as.integer(as.hexmode("51")), as.integer(as.hexmode("b5")), maxColorValue = 255)
amber500 <- rgb(as.integer(as.hexmode("ff")), as.integer(as.hexmode("c1")), as.integer(as.hexmode("07")), maxColorValue = 255)
yellow500 <- rgb(as.integer(as.hexmode("ff")), as.integer(as.hexmode("eb")), as.integer(as.hexmode("3b")), maxColorValue = 255)
purple500 <- rgb(as.integer(as.hexmode("67")), as.integer(as.hexmode("3a")), as.integer(as.hexmode("b7")), maxColorValue = 255)
grey500 <- rgb(as.integer(as.hexmode("9e")), as.integer(as.hexmode("9e")), as.integer(as.hexmode("b9")), maxColorValue = 255)
brown500 <- rgb(as.integer(as.hexmode("79")), as.integer(as.hexmode("55")), as.integer(as.hexmode("48")), maxColorValue = 255)
cyan500 <- rgb(as.integer(as.hexmode("00")), as.integer(as.hexmode("bc")), as.integer(as.hexmode("d4")), maxColorValue = 255)
lime500 <- rgb(as.integer(as.hexmode("cd")), as.integer(as.hexmode("dc")), as.integer(as.hexmode("39")), maxColorValue = 255)
black <- rgb(as.integer(as.hexmode("00")), as.integer(as.hexmode("00")), as.integer(as.hexmode("00")), maxColorValue = 255)


# Plots enriched GO terms in a scatter plot after clustering and filtering
plot_scatter_old <- function(cluster_representatives, output_dir) {
    file_path <- paste(output_dir, "GO_scatterplot.png", sep = "/")

    # Plot GO terms
    go_viz_names <- c("term_ID", "name", "plot_X", "plot_Y", "relative_size", "pvalue", "annotated_genes", "found_genes", "expected_genes")
    go_viz_data <- cbind(cluster_representatives$GO, cluster_representatives$name, cluster_representatives$x, cluster_representatives$y, cluster_representatives$size, cluster_representatives$pvalue,
        cluster_representatives$annotated_genes, cluster_representatives$found_genes, cluster_representatives$expected_genes)
    go_viz_data <- as.data.frame(go_viz_data)
    names(go_viz_data) <- go_viz_names
    go_viz_data$plot_X <- as.numeric(as.character(go_viz_data$plot_X))
    go_viz_data$plot_Y <- as.numeric(as.character(go_viz_data$plot_Y))
    go_viz_data$relative_size <- as.numeric(as.character(go_viz_data$relative_size))
    go_viz_data$pvalue <- as.numeric(as.character(go_viz_data$pvalue))

    Cairo::Cairo(file = file_path, type = "png", units = "in", width = 10, height = 7, pointsize = 12, dpi = 600)
    print({
        p1 <- ggplot2::ggplot(data = go_viz_data)
        p1 <- p1 + ggplot2::geom_point(ggplot2::aes(go_viz_data$plot_X, go_viz_data$plot_Y, colour = go_viz_data$pvalue, size = go_viz_data$relative_size), alpha = I(0.6))
        p1 <- p1 + ggplot2::scale_colour_gradientn("Significance", colours = c("red", "green"))
        p1 <- p1 + ggplot2::geom_point(ggplot2::aes(go_viz_data$plot_X, go_viz_data$plot_Y, size = go_viz_data$relative_size), shape = 21, fill = "transparent", colour = I(ggplot2::alpha("black", 0.6)))
        p1 <- p1 + ggplot2::scale_size("Frequency", range = c(5, 20), breaks = c(0, 0.02, 0.04), labels = c("0%", "2%", "4%"))
        p1 <- p1 + ggplot2::geom_text(data = go_viz_data[go_viz_data$pvalue < 0.01, ], aes(plot_X, plot_Y, label = paste(paste(term_ID, paste(round(relative_size * 100, 2), "%"), sep = ", "), paste(expected_genes,
            found_genes, sep = " / "), sep = ", ")), colour = I(alpha("black", 0.85)), size = 3, nudge_y = -0.01, check_overlap = F)
        p1 <- p1 + ggplot2::labs(y = "Y", x = "X")
        p1 <- p1 + ggplot2::theme(legend.key = ggplot2::element_blank())
        one.x_range <- max(go_viz_data$plot_X) - min(go_viz_data$plot_X)
        one.y_range <- max(go_viz_data$plot_Y) - min(go_viz_data$plot_Y)
        p1 <- p1 + ggplot2::xlim(min(go_viz_data$plot_X) - one.x_range / 10, max(go_viz_data$plot_X) + one.x_range / 10)
        p1 <- p1 + ggplot2::ylim(min(go_viz_data$plot_Y) - one.y_range / 10, max(go_viz_data$plot_Y) + one.y_range / 10)

    })
    dev.off()

    futile.logger::flog.info("Created plot: %s", file_path)
}

# Plots elements in a table
plot_table <- function(cluster_representatives, output_dir) {

    file_path <- paste(output_dir, "GO_terms.png", sep = "/")

    cluster_representatives_aux <- cluster_representatives[, c("GO", "name", "pvalue", "size", "expected_genes", "found_genes")]
    cluster_representatives_aux$size <- paste(round(cluster_representatives_aux$size * 100, 2), "%")
    cluster_representatives_aux$pvalue <- round(as.numeric(cluster_representatives_aux$pvalue), 4)

    base_size <- 9
    ttheme <- gridExtra::ttheme_default(core = list(fg_params = list(parse = FALSE, col = "black", fontsize = base_size)), colhead = list(fg_params = list(parse = FALSE, fontface = 2L, fontsize = base_size)),
        rowhead = list(fg_params = list(parse = FALSE, fontface = 3L, fontsize = base_size)))

    Cairo::Cairo(file = file_path, type = "png", units = "in", width = 10, height = 10, pointsize = 12, dpi = 600)
    print({
        tbl <- gridExtra::tableGrob(cluster_representatives_aux, rows = NULL, theme = ttheme)
        grid::grid.draw(tbl)
    })
    dev.off()

    futile.logger::flog.info("Created plot: %s", file_path)
}

# Plots GO term clusters in a treemap
plot_treemap <- function(enrichment_results, output_dir) {

    file_path <- paste(output_dir, "GO_treemap.png", sep = "/")

    go_viz_names <- c("term_ID", "description", "freqInDbPercent", "representative")
    go_viz_data <- cbind(enrichment_results$GO, enrichment_results$name, enrichment_results$size, enrichment_results$cluster_name)

    stuff <- data.frame(go_viz_data)
    names(stuff) <- go_viz_names

    stuff$freqInDbPercent <- as.numeric(as.character(stuff$freqInDbPercent))

    # check the tmPlot command documentation for all possible parameters - there are a lot more inflate.labels: set this to TRUE for space-filling group labels - good for posters
    Cairo::Cairo(file = file_path, type = "png", units = "in", width = 10, height = 7, pointsize = 12, dpi = 600)
    treemap::treemap(stuff, index = c("representative", "description"), vSize = "freqInDbPercent", type = "categorical", vColor = "representative", title = "Gene Ontology treemap", inflate.labels = FALSE,
        lowerbound.cex.labels = 0, bg.labels = "#CCCCCCAA", position.legend = "none", align.labels = list(c("left", "top"), c("center", "center")))
    dev.off()

    futile.logger::flog.info("Created plot: %s", file_path)
}

# Plots GO graph
plot_graph <- function(cluster_representatives, GOdata, output_dir) {
    file_path <- paste(output_dir, "GO_graph.png", sep = "/")

    scores <- as.numeric(cluster_representatives$pvalue)
    names(scores) <- cluster_representatives$GO
    Cairo::Cairo(file = file_path, type = "png", units = "in", width = 10, height = 7, pointsize = 12, dpi = 600)
    topGO::showSigOfNodes(GOdata, scores, firstSigNodes = min(10, length(cluster_representatives$GO)), wantedNodes = cluster_representatives$GO, useInfo = "all")
    dev.off()

    futile.logger::flog.info("Created plot: %s", file_path)
}


# Plots Venn diagram
plot_triple_venn <- function(set1, set2, set3, names, output_dir, file_name) {

    file_path <- paste(output_dir, file_name, sep = "/")

    Cairo::Cairo(file = file_path, type = "png", units = "in", width = 10, height = 7, pointsize = 12, dpi = 600)
    print({
        draw.triple.venn(area1 = length(set1), area2 = length(set2), area3 = length(set3), n12 = length(intersect(set1, set2)), n23 = length(intersect(set2, set3)), n13 = length(intersect(set1, set3)),
            n123 = length(intersect(set1, intersect(set2, set3))), category = names, lty = "blank", fill = c(red500, green500, indigo500))
    })
    dev.off()

    futile.logger::flog.info("Created plot: %s", file_path)
}

# Plot simple scatter
plot_simple_scatter <- function(matrix, groups, output_dir, file_name) {

    file_path <- paste(output_dir, file_name, sep = "/")

    Cairo::Cairo(file = file_path, type = "png", units = "in", width = 10, height = 7, pointsize = 12, dpi = 600)
    print({
        ggbiplot::ggbiplot(matrix, obs.scale = 1, var.scale = 1, groups = groups, ellipse = TRUE, circle = TRUE, var.axes = FALSE, color = "blue") + scale_color_discrete(name = "") + theme(legend.direction = "horizontal",
            legend.position = "top")
    })
    dev.off()

    futile.logger::flog.info("Created plot: %s", file_path)
}

# Plots simple heatmap
plot_heatmap <- function(matrix, tumor_types, output_dir, file_name) {

    file_path <- paste(output_dir, file_name, sep = "/")


    colors <- rainbow(length(levels(tumor_types)))
    color_map <- colors[tumor_types]

    # col_tumor_type = as.character(tumor_types) col_tumor_type[col_tumor_type == 'BRCA'] <- red500 col_tumor_type[col_tumor_type == 'OV'] <- green500

    Cairo::Cairo(file = file_path, type = "png", units = "in", width = 10, height = 7, pointsize = 12, dpi = 600)
    print({
        gplots::heatmap.2(matrix, col = gplots::redgreen(75), scale = "column", key = T, keysize = 1.5, density.info = "none", trace = "none", cexCol = 0.9, labRow = NA, RowSideColors = color_map)
    })
    dev.off()

    futile.logger::flog.info("Created plot: %s", file_path)
}

# Plots individuals
mixomics_plot_individuals <- function(data, names, output_dir, file_name) {

    file_path <- paste(output_dir, file_name, sep = "/")

    colors <- rainbow(length(levels(names)))
    color_map <- colors[names]

    # col_tumor_type = as.character(names) col_tumor_type[col_tumor_type == 'BRCA'] <- red500 col_tumor_type[col_tumor_type == 'OV'] <- green500

    Cairo::Cairo(file = file_path, type = "png", units = "in", width = 10, height = 7, pointsize = 12, dpi = 600)
    print({
        mixOmics::plotIndiv(data, comp = 1:2, ind.names = names, col = color_map)
    })
    dev.off()

    futile.logger::flog.info("Created plot: %s", file_path)
}

# Plots variables
mixomics_plot_variables <- function(data, output_dir, file_name) {

    file_path <- paste(output_dir, file_name, sep = "/")

    Cairo::Cairo(file = file_path, type = "png", units = "in", width = 10, height = 7, pointsize = 12, dpi = 600)
    print({
        mixOmics::plotVar(data, comp = 1:2, cutoff = 0.5, Y.label = "Comp 2", X.label = "Comp 1", cex = c(0.8, 0.8))
    })
    dev.off()

    futile.logger::flog.info("Created plot: %s", file_path)
}

# Plots a network of features
mixomics_plot_network <- function(spls_result, output_dir, file_name) {

    file_path <- paste(output_dir, file_name, sep = "/")

    # Gets the maximum correlation between any pair of variables from X and Y comp = 1:2 keep.X = apply(abs(spls_result$loadings$X), 1, sum) > 0 keep.Y = apply(abs(spls_result$loadings$Y), 1, sum) > 0
    # row.names = spls_result$names$X col.names = spls_result$names$Y row.names = row.names[keep.X] col.names = col.names[keep.Y] if (spls_result$mode == 'canonical') { cord.X = cor(spls_result$X[,
    # keep.X], spls_result$variates$X[, comp], use = 'pairwise') cord.Y = cor(spls_result$Y[, keep.Y], spls_result$variates$Y[, comp], use = 'pairwise') } else { cord.X = cor(spls_result$X[, keep.X],
    # spls_result$variates$X[, comp], use = 'pairwise') cord.Y = cor(spls_result$Y[, keep.Y], spls_result$variates$X[, comp], use = 'pairwise') } mat = cord.X %*% t(cord.Y)
    correlation_threshold <- 0.6  #min (0.6, max(abs(as.vector(t(mat)))))

    ## By setting keep.var = TRUE, we only display the variables selected by sPLS on dimensions 1 and 2
    color.edge <- colorRampPalette(c("darkgreen", "green", "yellow", "red", "darkred"))
    Cairo::Cairo(file = file_path, type = "png", units = "in", width = 10, height = 7, pointsize = 12, dpi = 600)
    print({
        mixOmics::network(spls_result, comp = 1:2, shape.node = c("rectangle", "rectangle"), color.node = c("white", "pink"), color.edge = color.edge(10), threshold = correlation_threshold)
    })
    dev.off()

    futile.logger::flog.info("Created plot: %s", file_path)
}

# Plots a heatmap
mixomics_plot_heatmap <- function(spls_result, output_dir, file_name) {

    file_path <- paste(output_dir, file_name, sep = "/")

    Cairo::Cairo(file = file_path, type = "png", units = "in", width = 10, height = 7, pointsize = 12, dpi = 600)
    print({
        mixOmics::cim(spls_result, comp = 1:3, xlab = "proteins", ylab = "genes", margins = c(5, 6))
    })
    dev.off()

    futile.logger::flog.info("Created plot: %s", file_path)
}

# Main MCIA composite plot
mcia_plot <- function(mcia_result, phenotype, output_dir, file_name) {

    file_path <- paste(output_dir, file_name, sep = "/")

    colors <- rainbow(length(levels(phenotype)))
    color_map <- colors[phenotype]

    # col.variables = c(indigo500, amber500) col.tumor.type = phenotype col.tumor.type[col.tumor.type == 'BRCA'] <- red500 col.tumor.type[col.tumor.type == 'OV'] <- green500

    Cairo::Cairo(file = file_path, type = "png", units = "in", width = 10, height = 7, pointsize = 12, dpi = 600)
    print({
        plot(mcia_result, axes = 1:2, phenovec = phenotype, sample.lab = FALSE, df.color = colors, sample.color = color_map, sample.legend = FALSE, gene.nlab = 5, df.pch = c(21, 22))
    })
    dev.off()

    futile.logger::flog.info("Created plot: %s", file_path)
}

mcia_plot_variables <- function(mcia_result, mcia_selected_variables, output_dir, file_name) {

    file_path <- paste(output_dir, file_name, sep = "/")

    Cairo::Cairo(file = file_path, type = "png", units = "in", width = 10, height = 7, pointsize = 12, dpi = 600)
    print({
        omicade4::plotVar(mcia_result, mcia_selected_variables, var.col = red500, var.lab = TRUE, bg.var.col = "grey")
    })
    dev.off()

    futile.logger::flog.info("Created plot: %s", file_path)
}

plot_samples_barplot <- function(Z, output_dir, file_name) {

    file_path <- paste(output_dir, file_name, sep = "/")

    Cairo::Cairo(file = file_path, type = "png", units = "in", width = 10, height = 7, pointsize = 12, dpi = 600)
    print({
        q <- ggplot2::qplot(x = Z$Tumor_type, data = Z, geom = "bar", fill = Z$vital_status, ylab = "Count", xlab = "Tumor type")
        q + ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1)) + ggplot2::geom_text(stat = "count", ggplot2::aes(label = ..count..), vjust = -1, size = 3, hjust = 0.5, position = "stack")
    })
    dev.off()

    futile.logger::flog.info("Created plot: %s", file_path)
}
