module Carto
  module Api
    class WidgetsController < ::Api::ApplicationController
      include Carto::ControllerHelper

      ssl_required :show, :create, :update

      before_filter :load_parameters
      before_filter :load_widget, only: [:show, :update]

      rescue_from Carto::LoadError, with: :rescue_from_carto_error
      rescue_from Carto::UnauthorizedError, with: :rescue_from_carto_error
      rescue_from Carto::UnprocesableEntityError, with: :rescue_from_carto_error

      def show
        render_jsonp(@widget.attributes)
      end

      def create
        widget = Carto::Widget.new(
          layer_id: @layer_id,
          order: Carto::Widget.where(layer_id: @layer_id).count + 1,
          type: params[:type],
          title: params[:title],
          dataview: params[:dataview].to_json)
        widget.save!
        render_jsonp(widget.attributes, 201)
      end

      def update
        @widget.order = params[:order] if params[:order]
        @widget.type = params[:type] if params[:type]
        @widget.title = params[:title] if params[:title]
        @widget.dataview = params[:dataview].to_json if params[:dataview]
        @widget.save

        render_jsonp(@widget.attributes)
      end

      private

      def load_parameters
        @map_id = params[:map_id]
        @map = Carto::Map.where(id: @map_id).first
        raise LoadError.new("Map not found: #{@map_id}") unless @map
        raise Carto::UnauthorizedError.new("Not authorized for map #{@map.id}") unless @map.writable_by_user?(current_user)

        @layer_id = params[:map_layer_id]
        payload_layer_id = params['layer_id']

        if [payload_layer_id, @layer_id].compact.uniq.length >= 2
          raise UnprocesableEntityError.new("URL layer id (#{@layer_id}) and payload layer id (#{payload_layer_id}) don't match")
        end

        @layer = Carto::Layer.where(id: @layer_id).first
        raise LoadError.new("Layer not found: #{@layer_id}") unless @layer

        @widget_id = params[:widget_id]
        if [@widget_id, params[:id]].compact.uniq.length >= 2
          raise UnprocesableEntityError.new("URL id (#{@widget_id}) and payload id (#{params[:id]}) don't match")
        end

        true
      end

      def load_widget
        @widget = Carto::Widget.where(layer_id: @layer_id, id: @widget_id).first

        raise Carto::LoadError.new("Widget not found: #{@widget_id}") unless @widget
        raise Carto::LoadError.new("Widget not found: #{@widget_id} for that map (#{@map_id})") unless @widget.belongs_to_map?(@map_id)
        raise Carto::UnauthorizedError.new("Not authorized for widget #{@widget_id}") unless @widget.writable_by_user?(current_user)

        true
      end
    end
  end
end
