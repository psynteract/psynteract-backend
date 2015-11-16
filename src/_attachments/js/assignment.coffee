generate_groups = (groups, players, groupings, design='perfect_stranger') ->
  # Count the players
  players_n = players.length

  # Check that the number of players is evenly
  # divisible by the number of groups
  if players_n % groups isnt 0
    alert 'The number of players needs to be evenly ' +
      'divisible by the number of groups.'

  # Shuffle the players to ensure random assignment
  players = _.shuffle players

  # Create an empty group array to be filled
  output = []

  # Calculate group size
  group_size = players_n / groups

  switch design
    when 'stranger'

      # For a stranger design, shuffle the players
      # and split them into groups
      for i in [1..groupings]
        grouping = []
        p = _.shuffle players

        for g in _.range(groups)
          grouping.push p.slice(g*group_size, (g+1)*group_size)

        output.push grouping

    when 'perfect_stranger'
      # Perfect stranger designs with more that two
      # players in a group are not yet supported.
      if group_size isnt 2
        alert 'Perfect stranger designs are not yet implemented ' +
          'for group sizes > 2'

      # A paired perfect stranger design can be
      # represented as a symmetrical latin square.
      latin_square = symmetrical_latin_square(players_n).next().value

      for g in _.range(groupings)
        grouping = []
        players_assigned = []

        for r, i in latin_square
          if i not in players_assigned
            # If player i has not yet been assigned her
            # partners, them in grouping g (+1, because
            # the matrix starts counting at 1)
            j = _.findIndex(r, (x) -> x is g + 1)

            # Make a pair from both of these partners
            grouping.push [players[i], players[j]]

            # Remember that the players have already
            # been used for this grouping
            players_assigned.push i
            players_assigned.push j

        # When a full assignment has been constructed,
        # add it to the final assignment matrix.
        output.push grouping

  return output

assign = (groups, players, groupings, design='perfect_stranger', roles=[], ghosts=false) ->
  # If the participants are provided as an integer
  # rather than an array, create an array of ascending
  # Integers instead.
  if typeof(players) is 'number'
    players = _.range(players)

  # Count players
  players_n = players.length

  # Shuffle the players to ensure random assignment
  players = _.shuffle players

  # If ghosts are enabled, and necessary,
  # seperate the ghosts from the actual players
  if ghosts and players_n % groups isnt 0
    ghosts_n = players_n % groups
    players_n = players_n - ghosts_n

    # Exclude ghosts from the assignment for the time being
    players_ghosts = players.slice(players_n, players_n + ghosts_n)
    players = players.slice(0, players_n)

    # The ghosts will share assignments with
    # randomly chosen (haunted, if you like) players
    players_haunted = players.slice(0, ghosts_n)

  group_lists = generate_groups(groups, players, groupings, design)
  groupings = groups_to_assignments(group_lists)
  roles = roles_to_dict(group_lists, roles)

  # Add 'haunted' assignments
  if ghosts and players_ghosts.length > 0
    # Map ghosts onto 'haunted' players
    haunts = _.zipObject players_ghosts, players_haunted

    # Update assignments by copying the partners
    # of the haunted players to the ghosts
    groupings = groupings.map (g) ->
      for haunt of haunts
        g[haunt] = g[haunts[haunt]]

      g

    roles = roles.map (r) ->
      for haunt of haunts
        r[haunt] = r[haunts[haunt]]

      r
  else
    haunts = {}

  return [group_lists, groupings, roles, haunts]

groups_to_assignments = (group_lists) ->
  # Return a dictionary representing the
  # partners of any single user
  return group_lists.map (grouping) ->
    o = {}

    # For every group in the assignment,
    # assign all other members to every single
    # member.
    for group in grouping
      for member in group
        o[member] = group.filter (m) -> m isnt member

    return o

roles_to_dict = (group_lists, roles) ->
  # Assign roles to players within groups
  return group_lists.map (grouping) ->

    reducer = (o, group) ->
      # Add player/role pairs to the object o,
      # where the roles are used in a random order
      _.extend o, _.zipObject(group, _.shuffle(roles))

    # Starting from an empty object, use the
    # function above to add player/role pairs
    grouping.reduce reducer, {}
