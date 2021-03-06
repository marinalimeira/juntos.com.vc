class ReupdateStatisticTotals < ActiveRecord::Migration
  def up
    execute <<-SQL
       DROP VIEW statistics;
       CREATE OR REPLACE VIEW statistics AS
       SELECT ( SELECT count(*) AS count
              FROM users) AS total_users,
       contributions_totals.total_contributions,
       contributions_totals.total_contributors,
       contributions_totals.total_contributed,
       projects_totals.total_projects,
       projects_totals.total_projects_success,
       projects_totals.total_projects_online
      FROM ( SELECT count(*) AS total_contributions,
               count(DISTINCT contributions.user_id) AS total_contributors,
               sum(contributions.project_value) AS total_contributed
              FROM (contributions
                LEFT JOIN projects ON ((contributions.project_id = projects.id)))
             WHERE (((contributions.state)::text <> ALL (ARRAY[('waiting_confirmation'::character varying)::text, ('invalid_payment'::character varying)::text, ('pending'::character varying)::text, ('canceled'::character varying)::text, 'deleted'::text])) AND ((projects.state)::text <> ALL (ARRAY[('draft'::character varying)::text, ('rejected'::character varying)::text, ('failed'::character varying)::text, ('deleted'::character varying)::text, ('in_analysis'::character varying)::text])))) contributions_totals,
       ( SELECT count(*) AS total_projects,
               count(
                   CASE
                       WHEN ((projects.state)::text = 'successful'::text) THEN 1
                       ELSE NULL::integer
                   END) AS total_projects_success,
               count(
                   CASE
                       WHEN ((projects.state)::text = 'online'::text) THEN 1
                       ELSE NULL::integer
                   END) AS total_projects_online
              FROM projects
             WHERE ((projects.state)::text <> ALL (ARRAY[('draft'::character varying)::text, ('rejected'::character varying)::text]))) projects_totals;
    SQL
  end

  def down
    execute <<-SQL
       DROP VIEW statistics;
       CREATE OR REPLACE VIEW statistics AS
       SELECT ( SELECT count(*) AS count
               FROM users) AS total_users,
        contributions_totals.total_contributions, contributions_totals.total_contributors,
        contributions_totals.total_contributed, projects_totals.total_projects,
        projects_totals.total_projects_success,
        projects_totals.total_projects_online
       FROM ( SELECT count(*) AS total_contributions,
                count(DISTINCT contributions.user_id) AS total_contributors,
                sum(contributions.value) AS total_contributed
               FROM contributions
          LEFT JOIN projects ON contributions.project_id = projects.id
              WHERE contributions.state::text <> ALL (ARRAY['waiting_confirmation'::character varying::text, 'invalid_payment'::character varying::text, 'pending'::character varying::text, 'canceled'::character varying::text, 'deleted'])
                AND projects.state::text <> ALL (ARRAY['draft'::character varying::text, 'rejected'::character varying::text, 'failed'::character varying::text, 'deleted'::character varying::text, 'in_analysis'::character varying::text])) contributions_totals,
        ( SELECT count(*) AS total_projects,
                count(
                    CASE
                        WHEN projects.state::text = 'successful'::text THEN 1
                        ELSE NULL::integer
                    END) AS total_projects_success,
                count(
                    CASE
                        WHEN projects.state::text = 'online'::text THEN 1
                        ELSE NULL::integer
                    END) AS total_projects_online
               FROM projects
              WHERE projects.state::text <> ALL (ARRAY['draft'::character varying::text, 'rejected'::character varying::text])) projects_totals;
    SQL
  end
end
