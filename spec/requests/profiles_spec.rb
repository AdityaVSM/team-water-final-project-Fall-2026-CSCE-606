require "rails_helper"

RSpec.describe "Profiles", type: :request do
  let(:user) { User.create!(name: "Dheeraj", email: "dheeraj@example.com", password: "password123") }

  describe "PATCH /profile" do
    context "when logged in" do
      before do
        post login_path, params: { email: user.email, password: "password123" }
      end

      it "updates the avatar_key to a preset" do
        patch profile_path, params: { user: { avatar_key: "cat" } }
        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to eq("Avatar updated successfully!")
        expect(user.reload.avatar_key).to eq("cat")
      end

      it "updates the avatar_key to gravatar" do
        patch profile_path, params: { user: { avatar_key: "gravatar" } }
        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to eq("Avatar updated successfully!")
        expect(user.reload.avatar_key).to eq("gravatar")
      end

      it "updates the avatar_key back to initials" do
        user.update!(avatar_key: "plant")
        patch profile_path, params: { user: { avatar_key: "initials" } }
        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to eq("Avatar updated successfully!")
        expect(user.reload.avatar_key).to eq("initials")
      end
    end

    context "when not logged in" do
      it "redirects to login path" do
        patch profile_path, params: { user: { avatar_key: "cat" } }
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
