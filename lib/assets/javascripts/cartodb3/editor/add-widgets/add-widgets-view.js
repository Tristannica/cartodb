var _ = require('underscore');
var cdb = require('cartodb.js');
var LoadingView = require('../../components/loading/loading-view');
var AddWidgetsBodyView = require('./add-widgets-body-view');
var template = require('./add-widgets.tpl');

/**
 * View to add new widgets.
 * Expected to be rendered in a modal
 */
module.exports = cdb.core.View.extend({
  className: 'Dialog-content Dialog-content--expanded',

  events: {
    'click .js-continue': '_onContinue'
  },

  initialize: function (opts) {
    if (!opts.modalModel) throw new Error('modalModel is required');
    if (!opts.tablesCollection) throw new Error('tablesCollection is required');
    if (!opts.layerDefinitionsCollection) throw new Error('layerDefinitionsCollection is required');

    this._modalModel = opts.modalModel;
    this._tablesCollection = opts.tablesCollection;
    this._layerDefinitionsCollection = opts.layerDefinitionsCollection;

    if (!this._hasFetchedAllTables()) {
      this._fetchUnfetchedTables();
      this.listenTo(this._tablesCollection, 'change:fetched', this._onTableFetched);
    }
  },

  render: function () {
    this.clearSubViews();
    this.$el.html(template());

    var view = new LoadingView({
      el: this.$('.js-body'),
      title: _t('editor.add-widgets.fetching-tables-title'),
      predicate: this._hasFetchedAllTables.bind(this),
      createContentView: this._newBodyView.bind(this)
    });
    this.addView(view);
    view.render();

    return this;
  },

  _onContinue: function () {
    var didConfirm = confirm('ORLY?'); // eslint-disable-line
    if (didConfirm) {
      this._modalModel.destroy();
    }
  },

  _hasFetchedAllTables: function () {
    var t = this._tablesCollection;
    return t.filter(t.isFetched).length === t.length;
  },

  _fetchUnfetchedTables: function () {
    var t = this._tablesCollection;
    var isNotFetched = _.compose(_.negate(Boolean), t.isFetched);
    t.chain()
      .filter(isNotFetched)
      .each(function (m) {
        m.fetch();
      });
  },

  _onTableFetched: function () {
    if (this._hasFetchedAllTables()) {
      this.render();
    }
  },

  /**
   * @param {Object} opts
   * @param {HTMLElement} opts.el
   */
  _newBodyView: function (opts) {
    return new AddWidgetsBodyView({
      el: opts.el,
      layerDefinitionsCollection: this._layerDefinitionsCollection
    });
  }
});