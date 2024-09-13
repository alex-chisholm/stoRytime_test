library(shiny)
library(bslib)
library(quarto)
library(httr2)
library(base64enc)

addResourcePath('www', 'www')

drawing_instructions <- "This scene should be illustrated in a storybook style with soft, pastel colors, whimsical and child-friendly illustrations with gentle lines. The image should evoke warmth and wonder, resembling hand-drawn artwork with simplicity and charm, like classic fairy tales."


ui <- page_fluid(
  theme = bs_theme(version = 5, bootswatch = "darkly"),
  
  layout_columns(
    col_widths = breakpoints(
      sm = c(12),
      md = c(12),
      lg = c(3, 9)
    ),
    card(
      card_header("Settings"),
      textAreaInput(
        "story_prompt",
        label = "Write the first sentence of your story:",
        width = "100%",
        height = "100px"
      ),
      numericInput("num_of_sentences", 
                   label = "Number of sentences:", 
                   value = 5, min = 2, max = 10),
      textAreaInput(
        "drawing_instructions",
        label = "Instructions for drawing images:",
        value = drawing_instructions,
        width = "100%",
        height = "200px"
      ),
      input_task_button("create_story", "Create Story")
    ),
    
    card(
      card_header(
        "Story",
        popover(
          placement = "right",
          bsicons::bs_icon("gear", class = "ms-auto"),
          selectInput(
            "story_theme",
            label = "Select theme:",
            choices = c("dark", "beige", "blood", "league", "moon", "night",
                        "serif", "simple", "sky", "solarized", "default")
          ),
          textInput(
            "story_title",
            label = "Provide a story title:",
            value = "stoRy time with shiny and quarto"
          ),
          input_task_button("update_theme", "Update Theme"),
          title = "Presentation settings"
        ),
        class = "d-flex align-items-center gap-1"
      ),
      htmlOutput("html_story"), min_height = 600
    )
    
  )
)


server <- function(input, output, session) {
  
  story <- reactiveVal()
  all_imgs <- reactiveVal()
  
  
  observeEvent(input$create_story, {
   
    if (input$story_prompt != ""){
    
      # Get story from Workers AI model
      new_story <- get_story(
          prompt = input$story_prompt,
          num_of_sentences = input$num_of_sentences
          )
  
      story(new_story)
      
      # Instructions for drawing each scene
      image_prompt <- paste0(
          "The background information for this scene is: ",
          input$story_prompt,
          ". 
        ", 
          input$drawing_instructions
        )
      
      # Get images from Workers AI model
      reqs <- lapply(
          story(),
          function(x){
            req_single_image(x, image_prompt)
          }
        )
        
      resps <- httr2::req_perform_parallel(reqs, on_error = "continue")
      
      # All images
      new_all_imgs <- lapply(resps, get_image)
      all_imgs(new_all_imgs)
  
    } 
  
  }, ignoreInit = TRUE)
  
  
  
  observeEvent(input$create_story | input$update_theme, {
    
    quarto::quarto_render(input = "www/example.qmd", 
                          output_format = "all", 
                          metadata = list(theme = input$story_theme,
                                          "title-slide-attributes" = list(
                                            "data-background-image" = paste0("data:image/png;base64,", base64enc::base64encode(tail(all_imgs(), 1)[[1]])),
                                            "data-background-size" = "cover",
                                            "data-background-opacity" = 0.3
                                          )), 
                          quarto_args = c("--metadata", 
                                          paste0("title=", input$story_title)),
                          execute_params = list(
                            story_prompt = input$story_prompt,
                            story = story(), 
                            imgs = lapply(all_imgs(), base64encode)
                          )
    )
    
  }, ignoreInit = TRUE)
  
  html_content <- reactiveFileReader(
      intervalMillis = 5000,  # Check for changes every 5 seconds
      session = session,
      filePath = "www/example.html",
      readFunc = rvest::read_html
    )
  
  output$html_story <- renderUI({
    
    html_content()
    
    file_path <- "www/example.html"
    
    if (!file.exists(file_path)){
      return(tags$p("Waiting for the story..."))
    }
    
    tags$iframe(src= file_path,
                width="100%", 
                height=600)
  })
  
}

shinyApp(ui, server)