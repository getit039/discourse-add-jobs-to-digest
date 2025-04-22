# frozen_string_literal: true

DiscourseAddJobsToDigest::Engine.routes.draw do
  get "/examples" => "examples#index"
  # define routes here
end

Discourse::Application.routes.draw do
  mount ::DiscourseAddJobsToDigest::Engine, at: "discourse-add-jobs-to-digest"
end
