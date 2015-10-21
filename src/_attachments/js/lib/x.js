// x.coffee -- JavaScript/CoffeeScript implementation of Knuth's Algorithm X
// (c) 2015- Felix Henninger & contributors
// x.coffee is licensed under the MIT license.

var _, filter_constraints, invert_constraints, restore_constraints, solve;

invert_constraints = function(c) {
  var output;
  output = {};
  for (row of Object.keys(c)) {
    for (entry of c[row]) {
      output[entry] = output[entry] || []
      output[entry].push(row)
    }
  };
  return output;
};

_solve = function*(constraints, exemplars, solution) {
  var constraint, exemplars_removed, l, len, min_length, r, ref;
  if (solution == null) {
    solution = [];
  }
  if (_.isEmpty(constraints)) {
    return (yield solution);
  } else {
    min_length = _.min(_.map(constraints, function(c) {
      return c.length;
    }));
    constraint = _.findKey(constraints, function(c) {
      return c.length === min_length;
    });
    ref = constraints[constraint];
    for (l = 0, len = ref.length; l < len; l++) {
      r = ref[l];
      solution.push(r);
      exemplars_removed = filter_constraints(constraints, exemplars, r);
      for (s of _solve(constraints, exemplars, solution)) {
        yield s
      };
      restore_constraints(constraints, exemplars, r, exemplars_removed);
      solution.pop();
    }
  }
};

filter_constraints = function(constraints, exemplars, candidate) {
  var exemplars_removed, i, j, k, l, len, len1, len2, m, n, ref, ref1, ref2;
  exemplars_removed = [];
  ref = exemplars[candidate];
  for (l = 0, len = ref.length; l < len; l++) {
    j = ref[l];
    ref1 = constraints[j];
    for (m = 0, len1 = ref1.length; m < len1; m++) {
      i = ref1[m];
      ref2 = exemplars[i];
      for (n = 0, len2 = ref2.length; n < len2; n++) {
        k = ref2[n];
        if (k !== j) {
          _.remove(constraints[k], function(x) {
            return x === i;
          });
        }
      }
    }
    exemplars_removed.push(constraints[j]);
    delete constraints[j];
  }
  return exemplars_removed;
};

restore_constraints = function(constraints, exemplars, r, exemplars_removed) {
  var i, j, k, l, len, ref, results;
  ref = exemplars[r].reverse();
  results = [];
  for (l = 0, len = ref.length; l < len; l++) {
    j = ref[l];
    constraints[j] = exemplars_removed.pop();
    results.push((function() {
      var len1, m, ref1, results1;
      ref1 = constraints[j];
      results1 = [];
      for (m = 0, len1 = ref1.length; m < len1; m++) {
        i = ref1[m];
        results1.push((function() {
          var len2, n, ref2, results2;
          ref2 = exemplars[i];
          results2 = [];
          for (n = 0, len2 = ref2.length; n < len2; n++) {
            k = ref2[n];
            if (k !== j) {
              results2.push(constraints[k].push(i));
            } else {
              results2.push(void 0);
            }
          }
          return results2;
        })());
      }
      return results1;
    })());
  }
  return results;
};

solve = function(c) {
  return _solve(c, invert_constraints(c));
}
