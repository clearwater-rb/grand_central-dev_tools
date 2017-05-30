require 'clearwater'
require 'clearwater/black_box_node'

module GrandCentral
  class DevTools
    include Clearwater::Component

    def initialize store, element
      @store = store
      @app = Clearwater::Application.new(
        component: self,
        element: element,
      )
      @initial_state = store.state
      @dispatches = []
    end

    def start
      @app.render
      @store.on_dispatch do |old, new, action|
        @dispatches += [Dispatch.new(old, new, action)]
        @app.render
      end
    end

    def render
      div({
        style: {
          font_family: 'monospace',
          position: :fixed,
          background: '#555',
          color: :white,
          top: 0,
          right: 0,
          padding: '1em',
          box_shadow: '0 0 5px black',
          overflow: :scroll,
          box_sizing: 'border-box',
          max_height: '100vh',
        },
      }, [
        if @open
          div([
            div({ style: { text_align: :right } }, [
              button({ onclick: proc { @open = false; @app.render } }, '-'),
            ]),
            h2('State'),
            ModelPresenter.memoize(@store.state),
            h2('Actions'),
            div(@dispatches.map { |dispatch|
              DispatchPresenter.memoize(
                dispatch,
                oncommit: proc {
                  `#@store.state = #{dispatch.after}`
                  index = @dispatches.index dispatch
                  @dispatches = @dispatches[0..index]
                  call
                  @app.render
                },
                ondelete: proc {
                  @dispatches = @dispatches.reject { |d| d == dispatch }
                  new_dispatches = []
                  new_state = @dispatches.reduce(@initial_state) do |state, d|
                    s = `#@store.reducer`.call state, d.action
                    new_dispatches << Dispatch.new(state, s, d.action)
                    s
                  end
                  @dispatches = new_dispatches
                  `#@store.state = #{new_state}`
                  call
                  @app.render
                }
              )[dispatch.object_id]
            }),
          ])
        else
          div({ style: { text_align: :right } }, [
            span('Grand Central Dev Tools'),
            button({ onclick: proc { @open = true; @app.render } }, '+'),
          ])
        end,
      ])
    end

    # Dispatch = Struct.new(:before_state, :after_state, :action)
    class Dispatch
      attr_reader :before, :after, :action

      def initialize before, after, action
        @before = before
        @action = action
        @after = after
      end

      def == other
        return false unless other.class == self.class

        action == other.action
      end
    end

    class Presenter
      include Clearwater::Component

      attr_reader :model
      attr_accessor :placeholder

      def self.memoize *args, &block
        Placeholder.new(self, args, block)
      end

      def initialize model
        @model = model
      end

      def update model
        @model = model
      end

      def should_update? model
        !model.equal? @model
      end

      def update_self *args
        args = [@model] if args.empty?

        self.class.memoize(*args).update_self @placeholder, true
      end

      def serialize_value value
        case value
        when String, Numeric, true, false, nil
          code(value.inspect)
        when Array 
          ArrayPresenter.memoize value
        when Hash
          HashPresenter.memoize value
        else
          ModelPresenter.memoize value
        end
      end

      def set ivar, value
        proc do
          `self[ivar] = value`
          update_self model
        end
      end

      class Placeholder
        include Clearwater::BlackBoxNode

        attr_reader :klass, :key, :element, :node, :vdom

        def initialize klass, args, block
          @klass = klass
          @args = args
          @block = block
        end

        def [] key
          @key = key.to_s
          self
        end

        def component
          @component ||= @klass.new(*@args, &@block)
        end

        def node
          @node ||= Clearwater::Component.sanitize_content(component)
        end

        def mount element
          @vdom = Clearwater::VirtualDOM::Document.new(element)
          `#@vdom.tree = #{element.to_n}`
          `#@vdom.node = #{node}`
          `#@vdom.rendered = true`
          @component.placeholder = self
        end

        def update previous
          update_self previous
        end

        def update_self previous, override=false
          @vdom = previous.vdom
          @component = previous.component

          if override || component.should_update?(*@args, &@block)
            component.update(*@args, &@block)
            @component.placeholder = self
            @vdom.render component.render
          end
        end
      end
    end

    class ModelPresenter < Presenter
      def render
        attributes = model
          .instance_variables
          .map { |ivar| ivar.sub(/^@/, '') }
          .sort
          .map { |attr| [attr, `#{model}[#{attr}]`] }

        div({ style: { display: 'inline-block' } }, [
          h3({ style: { margin: 0 } }, model.class.name),
          table([
            tbody(attributes.map { |attr, value|
              tr({ key: attr, style: { vertical_align: :top } }, [
                th(attr),
                td(serialize_value value),
              ])
            }),
          ]),
        ])
      end
    end

    class ArrayPresenter < Presenter
      alias array model

      def render
        div({ style: { display: 'inline-block' } }, [
          '[',
          button({ onclick: set(:show_contents, !@show_contents) }, @show_contents ? '-' : "#{array.count} items"),
          if @show_contents
            div({ style: { padding_left: '1em' } }, [
              array.map { |item| div(serialize_value(item)) },
            ])
          end,
          ']',
        ])
      end
    end

    class HashPresenter < Presenter
      alias hash model

      def render
        div([
          '{',
          hash.any? ? button({ onclick: set(:show_contents, !@show_contents) }, @show_contents ? '-' : "#{hash.count} key#{'s' unless hash.one?}") : nil,
          if @show_contents
            div({ style: { padding_left: '2em' } }, hash.map { |k, v|
              div([
                div({ style: { display: 'inline-block', vertical_align: :top } }, serialize_value(k)),
                ' => ',
                div({ style: { display: 'inline-block', vertical_align: :top } }, serialize_value(v)),
              ])
            })
          end,
          '}',
        ])
      end
    end

    class DispatchPresenter < Presenter
      def initialize dispatch, oncommit: proc {}, ondelete: proc {}
        super dispatch
        @oncommit = oncommit
        @ondelete = ondelete
      end

      def update *args
        initialize *args
      end

      def render
        div([
          div([
            button({ onclick: set(:show_contents, !@show_contents) }, @show_contents ? '-' : '+'),
            button({ onclick: @oncommit }, '!'),
            button({ onclick: @ondelete }, 'x'),
            model.action.class.name,
          ]),
          if @show_contents
            dl({ style: { margin: 0 } }, [
              dt('Action'),
              dd(ModelPresenter.memoize(model.action)),
              dt('Before'),
              dd(ModelPresenter.memoize(model.before)),
              dt('After'),
              dd(ModelPresenter.memoize(model.after)),
            ])
          end,
        ])
      end

      def set ivar, value
        proc do
          `self[ivar] = value`
          update_self model, oncommit: @oncommit, ondelete: @ondelete
        end
      end
    end
  end
end
