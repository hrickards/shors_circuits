# Redirects user to circuits if a circuit exists in their sessionstorage
# i.e they've just signed in/registered

if sessionStorage.getItem('circuit')?
  window.location.replace("/circuits")
