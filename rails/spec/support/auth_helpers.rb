module AuthHelpers
  def sign_in_as(role)
    user = case role
           when :admin then create(:user, :admin)
           when :operador then create(:user, :operador)
           when :consulta then create(:user, :consulta)
           else create(:user, role: role)
           end
    sign_in user
    user
  end
end

RSpec.configure do |config|
  config.include AuthHelpers, type: :request
end
