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
