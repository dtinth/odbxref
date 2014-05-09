
angular.module('odbxref', ['ngRoute'])
.config(function($routeProvider, $locationProvider) {
  $routeProvider
  .when('/book/:id', {
    templateUrl: 'book.html',
    controller: 'BookController',
  })
  .when('/', {
    templateUrl: 'home.html',
    controller: 'HomeController'
  })
  .otherwise({redirectTo:'/'})
})
.factory('taskManager', function($q) {
  var exports = { }
  exports.items = [ ]
  exports.run = function(text, factory) {
    var defer = $q.defer()
    var item = { text: text, status: 'working' }
    function initiate() {
      item.status = 'working'
      factory().then(function(value) {
        exports.items.splice(exports.items.indexOf(item), 1)
        defer.resolve(value)
      }, function(error) {
        item.status = 'error'
        item.errorMessage = error.toString()
      })
    }
    item.retry = initiate
    initiate()
    exports.items.push(item)
    return defer.promise
  }
  return exports
})
.factory('resourceManager', function(taskManager, $http, $q) {
  var exports = { }
  exports.load = function(url) {
    return taskManager.run('Loading ' + url, function() {
      return $http.get(url).then(function(e) {
        return e.data
      }, function(e) {
        return $q.reject(new Error("HTTP Error " + e.status))
      })
    })
  }
  return exports
})
.factory('resources', function(resourceManager) {
  var exports = {}
  var books = {}
  exports.books = resourceManager.load('chapters/index.json')
  exports.book = function(id) {
    return books[id] || (books[id] = resourceManager.load('chapters/' + id + '.json'))
  }
  return exports
})
.controller('MainController', function($scope, taskManager, resources) {
  $scope.task = taskManager
  resources.books.then(function(data) {
    $scope.announceState = data.state
  })
})
.controller('HomeController', function($scope, resources) {
  $scope.groups = []
  resources.books.then(function(data) {
    $scope.groups = [
      data.books.slice(0, 22),
      data.books.slice(22, 39),
      data.books.slice(39)
    ]
  })
})
.controller('BookController', function($scope, resources, $routeParams) {
  var id = $routeParams.id
  $scope.chapters = [ ]
  resources.books.then(function(data) {
    data.books.forEach(function(book) {
      if (book.id == id) {
        $scope.book = book
      }
    })
    resources.book(id).then(function(data) {
      var keys = Object.keys(data)
      keys.sort(function(a, b) {
        return a - b
      })
      keys.forEach(function(chapterNumber) {
        var articles = data[chapterNumber]
        var chapter = {
          number: chapterNumber,
          articles: articles
        }
        $scope.chapters.push(chapter)
      })
    })
  })
})
.controller('ChapterController', function($scope) {
  function t(x) {
    return '-' + (x < 10 ? '0' : '') + x
  }
  $scope.fmtDate = function(date) {
    return date[0] + t(date[1]) + t(date[2])
  }
  $scope.bible = function(p) {
    return 'http://www.biblegateway.com/passage/?search=' + encodeURIComponent(p.passage)
  }
  function Sorter(initial, predicates) {
    var sorter = { }
    sorter.reverse = false
    sorter.class = function(predicate) {
      var active = predicate == sorter.predicateName
      return {
        'sorta-down': active && !sorter.reverse,
        'sorta-up':   active && sorter.reverse,
        'sorta':     true
      }
    }
    sorter.getPredicate = function() {
      
    }
    sorter.sort = function(predicate) {
      if (sorter.predicateName == predicate) {
        sorter.reverse = !sorter.reverse
      } else {
        sorter.predicateName = predicate
        sorter.predicate = predicates[predicate]
        sorter.reverse = false
      }
    }
    sorter.sort(initial)
    return sorter
  }
  function textSort(getter) {
    return function(item) {
      return getter(item).match(/[a-zA-Z]/)[0].toLowerCase()
    }
  }
  $scope.sorter = Sorter('date', {
    date: function(item) { return $scope.fmtDate(item.date) },
    title: textSort(function(item) { return item.title }),
    author: textSort(function(item) { return item.author[0] }),
    passage: [
      function(item) { return item.passage_ref[0][0][1] },
      function(item) { return item.passage_ref[0][0][2] }
    ]
  })
})




