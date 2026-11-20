module ApplicationHelper
  def user_avatar_tag(user, size: :md, extra_class: nil)
    return "" unless user

    classes = [ "user-avatar", "user-avatar--#{size}", extra_class ].compact.join(" ")

    case user.avatar_mode
    when :gravatar
      image_tag(
        user.gravatar_url(size == :lg ? 120 : (size == :sm ? 48 : 80)),
        alt: user.name,
        class: "#{classes} user-avatar-img",
        loading: "lazy"
      )
    when :preset
      content_tag(
        :span,
        user.avatar_emoji,
        class: "#{classes} user-avatar-emoji",
        style: "background-color: #{user.avatar_bg};",
        "aria-hidden": "true",
        title: user.name
      )
    else
      content_tag(
        :span,
        user.name.first.upcase,
        class: "#{classes} user-avatar-initials",
        "aria-hidden": "true",
        title: user.name
      )
    end
  end
end
