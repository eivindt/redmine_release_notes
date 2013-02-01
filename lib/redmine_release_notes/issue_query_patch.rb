
module RedmineReleaseNotes
  module IssueQueryPatch
    extend Patch

    def self.do_patch(klass)
      klass.class_eval do
        # make IssueQueries aware of ReleaseNotesQueryColumns
        add_available_column(ReleaseNotesQueryColumn.new)

        # chain available_filters so that the release notes query filter is
        # included in the list of available filters, if the query has a project
        # which has release notes enabled
        def available_filters_with_release_notes
          filters = available_filters_without_release_notes

          if project && project.module_enabled?(:release_notes)
            release_note_values = ReleaseNote.statuses.map do |status|
              [I18n.t(status, :scope => 'release_notes.status'), status]
            end
            filters["release_notes"] ||= {
              :type => :list,
              :name => I18n.t('release_notes.title_plural'),
              :values => release_note_values,
              :order => filters.size + 1
            }
          end

          filters
        end

        alias_method_chain :available_filters, :release_notes
        
        # add a method to generate the part of the WHERE clause for the
        # query's SQL statement
        def sql_for_release_notes_field(field, operator, value)
          db_table_alias = 'rn'
          db_field = 'status'
          sql_for_field('release_notes', operator, value, db_table_alias, db_field)
        end

        # chain joins_for_order_statement so that the statement also joins
        # the release_notes table
        def joins_for_release_notes
          "LEFT OUTER JOIN #{ReleaseNote.table_name} rn on rn.issue_id = #{queried_table_name}.id"
        end

        def joins_for_order_statement_with_release_notes(order_options)
          joins = joins_for_order_statement_without_release_notes(order_options) || ""
          joins << " " << joins_for_release_notes
        end

        alias_method_chain :joins_for_order_statement, :release_notes

        # Override issue_count so that the join is included
        def issue_count
          Issue.visible.count(:include => [:status, :project],
                              :joins => joins_for_release_notes,
                              :conditions => statement)
        rescue ::ActiveRecord::StatementInvalid => e
          raise StatementInvalid.new(e.message)
        end
      end
    end
  end
end
