class SwaggerUi extends Backbone.Router

  # Defaults
  dom_id: "swagger_ui"

  # Attributes
  options: null
  api: null
  headerView: null
  mainView: null

  # SwaggerUi accepts all the same options as SwaggerApi
  initialize: (options={}) ->
    # Allow dom_id to be overridden
    if options.dom_id?
      @dom_id = options.dom_id
      delete options.dom_id

    # Create an empty div which contains the dom_id
    $('body').append('<div id="' + @dom_id + '"></div>') if not $('#' + @dom_id)?

    @options = options

    # Set the callbacks
    @options.success = => @render()
    @options.progress = (d) => @showMessage(d)
    @options.status = (d) => @showStatus(d)
    @options.failure = (d) => @onLoadFailure(d)

    # Create view to handle the header inputs
    @headerView = new HeaderView({el: $('#header')})

    # Event handler for when the baseUrl/apiKey is entered by user
    @headerView.on 'update-swagger-ui', (data) => @updateSwaggerUi(data)

  # Event handler for when url/key is received from user
  updateSwaggerUi: (data) ->
    @options.discoveryUrl = data.discoveryUrl
    @options.apiKey = data.apiKey
    @options.apiLogin = data.apiLogin
    @options.apiPassword = data.apiPassword
    
    self = @
    
    if data.apiLogin
      @options.progress("authenticating "+data.apiLogin+" ...")
      $.ajax self.api.basePath+"/authentications", 
        type: "POST"
        contentType: "application/json"
        dataType: "json"
        data: JSON.stringify({email:data.apiLogin, password:data.apiPassword})
        success : (data) ->
          self.options.status("authenticated "+self.options.apiLogin+" ("+data.accessToken+")")
          self.options.accessToken = data.accessToken
          self.load() 
        error : (jqXHR, textStatus, errorThrown) ->
          self.options.progress("error: "+errorThrown)        
    else 
      self.options.phoenixAuth = null
      @load()
      
  # Create an api and render
  load: ->
    # Initialize the API object
    @mainView?.clear()
    @options.headers = {}
    @options.supportHeaderParams = true
    if @options.accessToken
      @options.headers['X-Jelli-Authentication'] = 'accessToken='+ @options.accessToken
      
    @headerView.update(@options.discoveryUrl, @options.apiKey)
    @api = new SwaggerApi(@options)

  # This is bound to success handler for SwaggerApi
  #  so it gets called when SwaggerApi completes loading
  render:() ->
    @showMessage('Finished Loading Resource Information. Rendering Swagger UI...')
    @mainView = new MainView({model: @api, el: $('#' + @dom_id)}).render()
    @showMessage()
    switch @options.docExpansion
     when "full" then Docs.expandOperationsForResource('')
     when "list" then Docs.collapseOperationsForResource('')
    @options.onComplete(@api, @) if @options.onComplete
    setTimeout(
      =>
        Docs.shebang()
      400
    )

  # Shows message on topbar of the ui
  showMessage: (data = '') ->
    $('#message-bar').removeClass 'message-fail'
    $('#message-bar').addClass 'message-success'
    $('#message-bar').html data

  showStatus: (data = '') ->
    $('#status-bar').removeClass 'message-fail'
    $('#status-bar').addClass 'message-success'
    $('#status-bar').html data

  # shows message in red
  onLoadFailure: (data = '') ->
    $('#message-bar').removeClass 'message-success'
    $('#message-bar').addClass 'message-fail'
    val = $('#message-bar').html data
    @options.onFailure(data) if @options.onFailure?
    val

window.SwaggerUi = SwaggerUi
