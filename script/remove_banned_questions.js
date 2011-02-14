db["questions"].find({"title" : null}).forEach(
  function(q){ db["questions"].remove(q); }
);
