assign = (groups, players, groupings, design='perfect_stranger') ->
  # If the participants are provided as an integer
  # rather than an array, create an array of ascending
  # Integers instead.
  if typeof(players) is 'number'
    players_n = players
    players = _.range(players)
  else
    players_n = players.length

  # Check that the number of players is evenly
  # divisible by the number of groups
  if players_n % groups isnt 0
    alert 'The number of players needs to be evenly ' +
      'divisible by the number of groups.'

  # Shuffle the players to ensure random assignment
  players = _.shuffle players

  # Create an empty assignment array to be filled
  assignments = []

  # Calculate group size
  group_size = players_n / groups

  switch design
    when 'stranger'

      # For a stranger design, shuffle the players
      # and split them into groups
      for i in [1..groupings]
        assignment = []
        p = _.shuffle players

        for g in _.range(groups)
          assignment.push p.slice(g*group_size, (g+1)*group_size)

        assignments.push assignment

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
        assignment = []
        players_assigned = []

        for r, i in latin_square
          if i not in players_assigned
            # If player i has not yet been assigned her
            # partners, them in grouping g (+1, because
            # the matrix starts counting at 1)
            j = _.findIndex(r, (x) -> x is g + 1)

            # Make a pair from both of these partners
            assignment.push [players[i], players[j]]

            # Remember that the players have already
            # been used for this grouping
            players_assigned.push i
            players_assigned.push j

        # When a full assignment has been constructed,
        # add it to the final assignment matrix.
        assignments.push assignment

  return assignments

assignments_to_dict = (assignments) ->
  # Return a dictionary representing the
  # partners of any single user
  return assignments.map (assignment) ->
    o = {}

    # For every group in the assignment,
    # assign all other members to every single
    # member.
    for group in assignment
      for member in group
        o[member] = group.filter (m) -> m isnt member

    return o

roles_to_dict = (assignments, roles) ->
  # Assign roles to players within groups
  return assignments.map (assignment) ->

    reducer = (o, group) ->
      # Add player/role pairs to the object o,
      # where the roles are used in a random order
      _.extend o, _.zipObject(group, _.shuffle(roles))

    # Starting from an empty object, use the
    # function above to add player/role pairs
    assignment.reduce reducer, {}
