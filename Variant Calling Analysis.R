library(shiny)
library(shinydashboard)

options(shiny.maxRequestSize = 1000 * 1024^2)

# UI
ui <- dashboardPage(
  skin = "purple",
  dashboardHeader(title = "Variant Calling Analysis"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("FASTQC", tabName = "fastqc", icon = icon("file")),
      menuItem("TRIMMOMATIC", tabName = "trimmomatic", icon = icon("scissors")),
      menuItem("FASTQC post Trimming", tabName = "fastqc_trimmed", icon = icon("file")),
      menuItem("BWA", tabName = "bwa", icon = icon("align-left")),
      menuItem("Variant Calling Analysis", tabName = "variant_calling", icon = icon("file-alt")),
      menuItem("SnpEff Annotation", tabName = "snp_eff", icon = icon("file"))
    )
  ),
  
  dashboardBody(
    tags$head(
      tags$style(HTML("
      .skin-purple .main-header .logo {
        background: linear-gradient(to right, #001f3f, #6f42c1);
      }
      .skin-purple .main-header .navbar {
        background: linear-gradient(to right, #001f3f, #6f42c1);
      }
      .skin-purple .main-sidebar {
        background: linear-gradient(to bottom, #001f3f, #6f42c1);
      }
      .skin-purple .main-sidebar .sidebar .sidebar-menu a {
        color: #c2c6d0;
      }
      .skin-purple .main-sidebar .sidebar .sidebar-menu a:hover {
        background-color: #6f42c1;
        color: white;
      }
      .skin-purple .main-footer {
        background: linear-gradient(to right, #001f3f, #6f42c1);
        color: white;
      }
      .content-wrapper {
        background-image: url(https://waifu2x.booru.pics/outfiles/54b26e16e6c62891a8921ef4687c4a5308b60e6d_s2_n2_y1.jpg);
        background-size: cover;
        background-repeat: no-repeat;
        background-attachment: fixed;
      }
      .box {
        background-color: rgba(255, 255, 255, 0.8);
      }
      .well {
        background-color: rgba(255, 255, 255, 0.5);
        border: 1px solid rgba(255, 255, 255, 0.3);
      }
      .well label {
        color: #000;
        font-weight: bold;
        text-shadow: 0px 0px 3px rgba(255, 255, 255, 0.8);
      }
      .btn-default {
        background-color: rgba(255, 255, 255, 0.7);
        border-color: rgba(0, 0, 0, 0.2);
      }
      .btn-default:hover {
        background-color: rgba(255, 255, 255, 0.9);
      }
    "))
    ),
    tabItems(
      tabItem(tabName = "fastqc",
              sidebarLayout(
                sidebarPanel(
                  fileInput("fastq", "Upload your FASTQ file", accept = ".fastq"),  
                  actionButton("fastqc", "Run FastQC")
                ),
                mainPanel(
                  uiOutput("fastqc_report") 
                )
              )
      )
      
      ,
      
      tabItem(tabName = "trimmomatic",
              sidebarLayout(
                sidebarPanel(
                  fileInput("adapterFile", "Upload Adapter File (FASTA)"),
                  numericInput("leading", "Leading Quality Threshold", value = 3, min = 0),
                  numericInput("trailing", "Trailing Quality Threshold", value = 3, min = 0),
                  numericInput("windowSize", "Sliding Window Size", value = 4, min = 1),
                  numericInput("qualityThreshold", "Quality Threshold", value = 15, min = 1),
                  numericInput("minLen", "Minimum Length", value = 36, min = 1),
                  actionButton("trimmomatic", "Run Trimmomatic")
                ),
                mainPanel(
                  tableOutput("trimmomatic_results"),
                  downloadButton("download_forward_paired", "Download Forward Paired"),
                  downloadButton("download_reverse_paired", "Download Reverse Paired"),
                  downloadButton("download_forward_unpaired", "Download Forward Unpaired"),
                  downloadButton("download_reverse_unpaired", "Download Reverse Unpaired")
                )
              )
      ),
      
      tabItem(tabName = "fastqc_trimmed",
              sidebarLayout(
                sidebarPanel(
                  fileInput("trimmed_files", "Upload your TRIMMED FASTQ files (forward and reverse)", accept = ".fastq", multiple = TRUE),
                  actionButton("fastqc_trimmed", "Run trimmed FastQC")
                ),
                mainPanel(
                  uiOutput("fastqc_trimmed_report")  
                )
              )
      )
      ,
      
      tabItem(tabName = "bwa",
              sidebarLayout(
                sidebarPanel(
                  fileInput("ref_genome", "Upload your reference genome (FASTA)", accept = ".fasta"),
                  fileInput("fastq_files", "Upload your FASTQ files (forward and reverse)", multiple = TRUE, accept = ".fastq"),
                  actionButton("BWA", "Run BWA Alignment")
                ),
                mainPanel(
                  tableOutput("BWA_results"),
                  downloadButton("download_bam", "Download BAM File")
                )
              )
      ),
      
      tabItem(tabName = "variant_calling",
              sidebarLayout(
                sidebarPanel(
                  fileInput("ref_genome_vc", "Upload Reference Genome (FASTA)", accept = ".fasta"),
                  fileInput("bam_file", "Upload Aligned BAM File", accept = ".bam"),
                  actionButton("variant_calling", "Run BCF Variant Calling")
                ),
                mainPanel(
                  tableOutput("vcf_results"),
                  downloadButton("download_vcf", "Download VCF File")
                )
              )
      ),
      
      tabItem(tabName = "snp_eff",
              sidebarLayout(
                sidebarPanel(
                  fileInput("vcf_file", "Upload VCF File", accept = ".vcf"),
                  actionButton("snp_eff", "Run SnpEff Annotation")
                ),
                mainPanel(
                  tableOutput("snp_eff_results"),
                  downloadButton("download_annotated_vcf", "Download Annotated VCF")
                )
              )
      )
    )
  )
)

server <- function(input, output, session) {
  
  observeEvent(input$fastqc, {
    req(input$fastq)
    
    # directory for fastqc results
    output_dir <- normalizePath("fastqc_results", mustWork = FALSE)
    dir.create(output_dir, showWarnings = FALSE)
    
    base_name <- tools::file_path_sans_ext(basename(input$fastq$name))
    
    # paths for split files in the output directory
    forward_reads <- file.path(output_dir, paste0(base_name, "_forward.fastq"))
    reverse_reads <- file.path(output_dir, paste0(base_name, "_reverse.fastq"))
    
    # Split the fastq file 
    tryCatch({
      system2("seqtk", 
              args = c("seq", "-1", shQuote(input$fastq$datapath)), 
              stdout = forward_reads)
      system2("seqtk", 
              args = c("seq", "-2", shQuote(input$fastq$datapath)), 
              stdout = reverse_reads)
    }, error = function(e) {
      showNotification("Error splitting FASTQ file. Please check if seqtk is installed.", type = "error")
      return()
    })
    
    # Verify split files exist
    if (!file.exists(forward_reads) || !file.exists(reverse_reads)) {
      showNotification("Error: Split files were not created successfully", type = "error")
      return()
    }
    
    # Run FastQC on both split files
    system2("fastqc", args = c(shQuote(forward_reads), "-o", shQuote(output_dir)))
    system2("fastqc", args = c(shQuote(reverse_reads), "-o", shQuote(output_dir)))
    
   
    fastqc_html_report_forward <- list.files(output_dir, 
                                             pattern = paste0(base_name, "_forward_fastqc.html$"), 
                                             full.names = TRUE)
    fastqc_html_report_reverse <- list.files(output_dir, 
                                             pattern = paste0(base_name, "_reverse_fastqc.html$"), 
                                             full.names = TRUE)
    
    if (length(fastqc_html_report_forward) > 0 && length(fastqc_html_report_reverse) > 0) {
      
      addResourcePath("fastqc_results", output_dir)
      
      output$fastqc_report <- renderUI({
        tagList(
          h4("Forward Reads FastQC Report"),
          tags$iframe(
            src = paste0("fastqc_results/", basename(fastqc_html_report_forward)), 
            width = "100%", 
            height = "600px", 
            frameborder = 0
          ),
          tags$a(
            href = paste0("fastqc_results/", basename(fastqc_html_report_forward)),
            "Download/View Full Forward FastQC Report", 
            target = "_blank", 
            style = "display:block; margin-top:10px; font-size:16px; color:#6f42c1;"
          ),
          
          h4("Reverse Reads FastQC Report"),
          tags$iframe(
            src = paste0("fastqc_results/", basename(fastqc_html_report_reverse)), 
            width = "100%", 
            height = "600px", 
            frameborder = 0
          ),
          tags$a(
            href = paste0("fastqc_results/", basename(fastqc_html_report_reverse)),
            "Download/View Full Reverse FastQC Report", 
            target = "_blank", 
            style = "display:block; margin-top:10px; font-size:16px; color:#6f42c1;"
          )
        )
      })
    } else {
      output$fastqc_report <- renderText("FastQC reports could not be generated. Please check your input file.")
    }
  })
