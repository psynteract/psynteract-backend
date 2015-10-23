# Template setup to fake Handlebars through lodash
_.templateSettings =
  'interpolate': /{{([\s\S]+?)}}/g

# Template preparation
client_context = _.template '
  <div id="controls-region" class="pull-right">
  </div>
  <h1>Session</h1>
  <p>These are your currently connected clients</p>
  <div id="clients-region">
  </div>
'

session_controls = _.template '
  <a class="btn btn-default btn-lg" href="/_utils/document.html?{{ db_name }}/{{ id }}"><i class="fa fa-cog"></i></a>
  <button class="btn btn-primary btn-lg" id="btn-update-status">{{ next_action }}</button>
'

client_table = _.template '
  <table id="clients" class="table table-striped">
    <thead>
      <tr>
        <th>Name</th>
        <th>ID</th>
        <th>Data</th>
        <th>Options</th>
      </tr>
    </thead>
    <tbody>
    </tbody>
  </table>
'

client_template = _.template '
  <td class="client_name">{{ name }}</td>
  <td><code>{{ id }}</code></td>
  <td class="client_data"><pre>{{ data }}</pre></td>
  <td>
    <div class="dropdown">
      <button class="btn btn-default btn-small dropdown-toggle" data-toggle="dropdown">
        <i class="fa fa-cog"></i>
        <span class="caret"></span>
      </button>
      <ul class="dropdown-menu">
        <li><a class="replace"><strong>Replace</strong> this client</a></li>
        <li><a href="/_utils/document.html?{{ db_name }}/{{ id }}"><strong>Show document</strong> in database</a></li>
      </ul>
    </div>
  </td>
'

sessions_context = _.template '
  <div id="controls" class="controls pull-right">
    <button class="btn btn-primary btn-lg" id="btn-new-session"><i class="fa fa-plus"></i> Start New Session</button>
  </div>
  <h1>Available Sessions</h1>
  <ul id="sessions">
  </ul>
  <table id="sessions" class="table table-striped">
    <thead>
      <tr>
        <th>Date</th>
        <th>ID</th>
        <th>Status</th>
        <th>Opened</th>
        <th>Options</th>
      </tr>
    </thead>
    <tbody>
    </tbody>
  </table>
'

session_template = _.template '
  <td><a href="#sessions/{{ id }}" class="session_detail">{{ date }}</a></td>
  <td><code><a href="#sessions/{{ id }}" class="session_detail">{{ id }}</a></code></td>
  <td>{{ status }}</td>
  <td>{{ ago }}</td>
  <td>
    <div class="btn-group">
      <a class="btn btn-default btn-small" type="button" href="/_utils/document.html?{{ db_name }}/{{ id }}"><i class="fa fa-cog"></i></a>
      <button class="btn btn-default btn-small dropdown-toggle" data-toggle="dropdown" type="button">
        <span class="caret"></span>
        <span class="sr-only">Toggle Dropdown</span>
      </button>
      <ul class="dropdown-menu" role="menu">
        <!-- dropdown menu links -->
      </ul>
    </div>
  </td>
'

# -------------------------------------------------------------------
# Connect to CouchDB
# Extract the database name from the url, as this may
# vary across installations
Backbone.couch_connector.config.db_name = unescape(document.location.href).split('/')[3]
# The design document is intended to stay fixed,
# but, just to be sure, we can look it up in a similar way.
Backbone.couch_connector.config.ddoc_name = unescape(document.location.href).split('/')[5]

# We don't need global changes, instead we'll let the
# views and collections take care of updating
Backbone.couch_connector.config.global_changes = on

# -------------------------------------------------------------------
# Initialize the marionette app

@App = new Backbone.Marionette.Application
@App.addRegions
  mainRegion:   '#main-region'
  modals:
    selector: '.modal-region'
    regionClass: Backbone.Marionette.Modals

@App.on 'start', (options) ->
  if Backbone.history
    Backbone.history.start()

  if Backbone.history.fragment == ''
    window.App.vent.trigger 'sessions:list'

# -------------------------------------------------------------------

# -------------------------------------------------------------------
# Views

@App.module 'Psynteract', (Psynteract, App, Backbone, Marionette, $, _) ->
  class Psynteract.Router extends Marionette.AppRouter
    appRoutes:
      'sessions/:id':    'showSession'
      'sessions':       'index'

  API =
    index: () ->
      Psynteract.Controller.showIndex()
    showSession: (id) ->
      Psynteract.SessionDetail.Controller.showSession id
    replaceClient: (session, clients, client_to_replace) ->
      Psynteract.ClientReplacement.Controller.replaceClient(
        session, clients, client_to_replace
      )

  App.vent.on 'sessions:show', (session) ->
    Backbone.history.navigate 'sessions/' + session.id
    API.showSession session.id

  App.vent.on 'sessions:list', (session) ->
    Backbone.history.navigate 'sessions'
    API.index()

  App.vent.on 'sessions:client:replace', (session, clients, client_to_replace) ->
    API.replaceClient session, clients, client_to_replace

  App.addInitializer ->
    new Psynteract.Router
      controller: API

@App.module 'Psynteract', (Psynteract, App, Backbone, Marionette, $, _) ->
  class Psynteract.Session extends Backbone.Model
    url: null

    defaults: ->
      type: 'session'
      status: 'open'
      opened: new Date()
      replace: {}

    status_values: ['open', 'running', 'closed', 'archived']
    status_asNum: =>
      @status_values.indexOf @get('status')

    next_status: () =>
      status_num = @status_asNum()

      if status_num == -1
        return undefined

      if status_num != @status_values.length - 1
        new_status = @status_values[status_num + 1]
      else
        new_status = @get('status')

      return new_status

    next_action: =>
      actions = ['start', 'close', 'archive', 'archived']
      return actions[@status_asNum()]

    update_status: =>
      @set 'status', @next_status()

    create_groupings: (clientList) =>
      # Create assignments (groups and roles)
      client_ids = clientList.pluck '_id'
      client_groups = clientList.pluck 'group'

      check_consensus = (list, label) ->
        # Setup a reducer to allow deep comparisons of the values provided
        first_elem = list[0]
        reducer = (value, input) ->
          # Perform a deep comparison between the first values
          # and the value currently under inspection.
          value and _.isEqual first_elem, input

        # Using the reducer, determin whether there is consensus between clients
        consensus = list.reduce(reducer, true)

        # If so, return a single configuration
        if consensus
          return first_elem
        else
          throw 'No consensus between clients with regard to ' + label

      # Check whether all clients agree on the design
      design = check_consensus clientList.pluck('design'), 'design'

      # If so, extract and compute the design parameters
      design_type = design['type']
      groupings = design['groupings_needed']
      group_size = design['group_size']
      roles = design['roles']
      players_n = clientList.length

      # Gnerate assignment
      assignments = assign players_n/group_size, client_ids, groupings, design_type

      console.log 'generating assignment with arguments', players_n/group_size, client_ids, groupings, design_type
      console.log 'assignments', assignments
      console.log 'groupings', assignments_to_dict(assignments)
      console.log 'roles', roles_to_dict(assignments, roles)

      @set 'groupings', assignments_to_dict(assignments)
      @set 'roles', roles_to_dict(assignments, roles)

    replace: (client_id, replacement_id) =>
      replacements = @get 'replace'
      replacements[client_id] = replacement_id
      @set 'replace', replacements
      @trigger 'change:replace'

  class Psynteract.SessionList extends Backbone.Collection
    model: Psynteract.Session
    db:
      view: 'sessions'
      changes: true
      filter: Backbone.couch_connector.config.ddoc_name + '/sessions'

    sortBy: =>
      models = _.sortBy @models, @comparator
      models.reverse()
      models

    comparator: 'opened'

  Psynteract.SessionTableRowView = Backbone.Marionette.ItemView.extend
    tagName: 'tr'
    template: session_template
    templateHelpers: () ->
      id: @model.id
      date: moment(@model.get "opened").format("MMMM Do YYYY, h:mm:ss a")
      ago: moment(@model.get "opened").fromNow()
      db_name: Backbone.couch_connector.config.db_name

    modelEvents:
      'change': 'render'

    events:
      'click a.session_detail': (e) ->
        e.preventDefault()
        @trigger 'sessions:show', @model

  Psynteract.NoSessionsView = Backbone.Marionette.ItemView.extend
    tagName: 'tr'
    template: _.template '<td colspan="5" style="text-align: center; padding: 40px;"><strong>No sessions yet.</strong> Please start a new one!</td>'

  Psynteract.SessionTableView = Backbone.Marionette.CompositeView.extend
    childView: Psynteract.SessionTableRowView
    childViewContainer: 'table#sessions tbody'
    template: sessions_context
    emptyView: Psynteract.NoSessionsView

    new_session: =>
      console.log 'creating new session'
      session = new Psynteract.Session()
      session.save {},
        success: (model, response, options) -> App.vent.trigger 'sessions:show', model
      #@trigger 'sessions:show', session

    ui:
      new_session: '#btn-new-session'

    events:
      'click @ui.new_session': 'new_session'

  Psynteract.Controller =
    showIndex: () ->
      view = new App.Psynteract.SessionTableView
        collection: window.sessions

      view.on 'childview:sessions:show', (iv, session) ->
        App.vent.trigger 'sessions:show', session

      view.on 'sessions:show', (v, session) ->
        console.log 'showing the new session'
        App.vent.trigger 'sessions:show', session

      App.mainRegion.show view

  App.addInitializer (options) =>
    window.sessions = new App.Psynteract.SessionList()
    window.sessions.fetch()
    window.sessions.sort()

@App.module 'Psynteract.SessionDetail', (SessionDetail, App, Backbone, Marionette, $, _) ->
  class SessionDetail.Client extends Backbone.Model

  class SessionDetail.ClientList extends Backbone.Collection
    model: SessionDetail.Client
    db: {}
    initialize: (opts) ->
      @db =
        key: opts.session_key
        view: "session_docs?key=\"" + opts.session_key + "\""
        changes: true
        filter: Backbone.couch_connector.config.ddoc_name + "/clients"
        type: "client"

    comparator: (model) ->
      model.get "name"

  censor = (key, value) ->
    return `undefined` if key[0] is "_"
    value

  SessionDetail.ClientView = Backbone.Marionette.ItemView.extend
    tagName: "tr"
    template: client_template

    initialize: (opts) ->
      @session = opts.session

    templateHelpers: () ->
      id: @model.id
      data: JSON.stringify @model.get('data'), censor, 2
      db_name: Backbone.couch_connector.config.db_name

    update: ->
      # Give the view a moment to re-render
      highlight = () => @$el.children('td').effect 'highlight'
      setTimeout highlight, 5

    onRender: () ->
      # Set the replaced css class on the table row
      # if the client has been replaced
      @$el.toggleClass 'replaced',
        @model.id in Object.keys(@session.get 'replace')

    modelEvents:
      'change:data': 'render update'

    events:
      'click a.replace': (e) -> @triggerMethod 'client:replace'

  SessionDetail.NoClientsView = Backbone.Marionette.ItemView.extend
    tagName: 'tr'
    template: _.template '<td colspan="4" style="text-align: center; padding: 40px;">
        <strong>No clients yet.</strong> Please start some!<br>
        <small style="color: #999">(if the clients don\'t appear,
        please make sure that this is the latest opened session)</small>
      </td>'

  SessionDetail.SessionView = Backbone.Marionette.CompositeView.extend
    template: client_table

    initialize: (opts) ->
      @session = opts.session

      # Update the view whenever the session
      # changes the replacement settings
      @session.on 'change:replace', @render, @
      # FIXME: This won't trigger when the change
      # is not made in the UI itself (for example,
      # when the change was made in futon)

    childView: SessionDetail.ClientView
    childViewContainer: 'table#clients tbody'
    childViewOptions: () ->
      session: @session

    emptyView: SessionDetail.NoClientsView

    childEvents:
      'client:replace': (v) ->
        App.vent.trigger 'sessions:client:replace',
          @session, @session.clients, v.model

  SessionDetail.SessionControlsView = Backbone.Marionette.ItemView.extend
    template: session_controls

    ui:
      update_status: '#btn-update-status'

    events:
      'click @ui.update_status': 'update_status'

    modelEvents:
      'change': 'render'

    templateHelpers: () ->
      id: @model.id
      next_action: @model.next_action()
      db_name: Backbone.couch_connector.config.db_name

    update_status: ->
      # This is somewhat hackish, but the model doesn't
      # have access to the containing session (yet?) :-|
      console.log "Updating status"
      if @model.next_status() == 'running'
        console.log 'Creating groupings'
        @model.create_groupings(@model.clients)

      @model.update_status()
      @model.save()

  SessionDetail.LayoutView = Backbone.Marionette.LayoutView.extend
    template: client_context
    regions:
      controlsRegion: '#controls-region'
      clientsRegion: '#clients-region'

  SessionDetail.Controller =
    showSession: (id) ->
      layout = new SessionDetail.LayoutView()
      App.mainRegion.show layout

      # TODO: Again, this is somewhat hackish.
      # The session controls need to access the clients,
      # and I haven't figured out a clean(er) way
      # to achieve this so far
      sessionview = new SessionDetail.SessionControlsView
        model: new App.Psynteract.Session({_id: id})

      sessionview.model.fetch()

      sessionview.model.clients = new SessionDetail.ClientList
        session_key: id
      sessionview.model.clients.fetch()

      clientsview = new SessionDetail.SessionView
        session: sessionview.model
        collection: sessionview.model.clients

      layout.controlsRegion.show sessionview
      layout.clientsRegion.show clientsview

@App.module 'Psynteract.ClientReplacement', (ClientReplacement, App, Backbone, Marionette, $, _) ->

  session_replacement_modal_template = _.template '
    <div class="modal-header">
      <button type="button" class="close modal-close" aria-label="Close">
        <span aria-hidden="true">&times;</span>
      </button>
      <h4 class="modal-title">Replace client</h3>
    </div>
    <div class="modal-body">
      <p>Please select the client with which to substitute its subsequently ignored colleague.</p>
      <div id="modalBodyRegion"></div>
    </div>
  '

  ClientView = Backbone.Marionette.ItemView.extend
    tagName: 'a'
    className: 'list-group-item'

    template: _.template """
      <span>{{ name ? name : '<span class=\"text-muted\">(No Name)</span>' }}</span>
      <code class="pull-right">{{ id }}</code>
      """

    templateHelpers: () ->
      id: @model.id

    events:
      'click': (e) -> @triggerMethod 'client:substitute'

  SessionView = Backbone.Marionette.CompositeView.extend
    template: _.template '<div class="list-group"></div>'
    childView: ClientView
    childViewContainer: 'div'

    initialize: (opts) ->
      @session = opts.session
      @client_to_replace = opts.client_to_replace
      @modal = opts.modal

    childEvents:
      'client:substitute': (v) ->
        if window.confirm 'Are you sure?'
          console.log "Replicing client #{ @client_to_replace.id }
            with #{ v.model.id } for session #{ @session.id }"
          @session.replace(@client_to_replace.id, v.model.id)
          @session.save()
          @modal.destroy()

  class ClientReplacementModal extends Backbone.Modal
    template: session_replacement_modal_template

    submitEl: '.modal-submit'
    cancelEl: '.modal-close'

    initialize: (@session, @clients, @client_to_replace) ->

    onShow: () ->
      # Create regions within the modal view
      @rm = new Marionette.RegionManager
        regions:
          'modalBodyRegion': '#modalBodyRegion'

      @rm.get('modalBodyRegion').show new SessionView
        collection: @clients
        session: @session
        client_to_replace: @client_to_replace
        modal: @

    onDestroy: () ->
      @rm.destroy()

  ClientReplacement.Controller =
    replaceClient: (session, clients, client_to_replace) ->
      view = new ClientReplacementModal(
        session, clients, client_to_replace
      )

      App.modals.show view


# -------------------------------------------------------------------

$ =>
  @App.start
    items: ''
