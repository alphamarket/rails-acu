require 'rails_helper'

RSpec.describe "comments/new", type: :view do
  before(:each) do
    assign(:comment, Comment.new(
      :book => nil,
      :text => "MyString"
    ))
  end

  it "renders new comment form" do
    render

    assert_select "form[action=?][method=?]", comments_path, "post" do

      assert_select "input#comment_book_id[name=?]", "comment[book_id]"

      assert_select "input#comment_text[name=?]", "comment[text]"
    end
  end
end
