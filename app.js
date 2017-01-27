cardGameApp = angular.module('CardGameApp', [])
.controller('CardDisplayController', CardDisplayController)
.directive('fileChange', fileChange);

CardDisplayController.$inject = ['$scope'];
function CardDisplayController($scope) {
  var cardDisplayController = this;
  cardDisplayController.cards = [];
  cardDisplayController.upload = function () {
    var reader = new FileReader();
    reader.onload = function(){
      var cards = JSON.parse(reader.result).drawn_cards;
      function cardValue(card) {
        value = card['value'];
        switch (card['value']) {
          case 'ACE':
            value = 00; break;
          case 'JACK':
            value = 11; break;
          case 'QUEEN':
            value = 12; break;
          case 'KING':
            value = 13; break;
        }
        return parseInt(value);
      }
      cardDisplayController.cards = cards.sort(function(a, b) {
        if (cardValue(a) < cardValue(b)) return -1;
        if (cardValue(a) > cardValue(b)) return 1;
        return 0;
      });
      $scope.$digest();
    };
    reader.readAsText(cardDisplayController.file);
  };

}

function fileChange() {
  return {
    restrict: 'A',
    require: 'ngModel',
    scope: {
      fileChange: '&'
    },
    link: function link(scope, element, attrs, ctrl) {
      element.on('change', onChange);

      scope.$on('destroy', function () {
        element.off('change', onChange);
      });

      function onChange() {
        ctrl.$setViewValue(element[0].files[0]);
        scope.fileChange();
      }
    }
  };
} 