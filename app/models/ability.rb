# frozen_string_literal: true

# Defines the abilities and permissions for users based on their role.
class Ability
  include CanCan::Ability

  # Initializes the abilities for a given user.
  #
  # @param user [User] The user whose abilities are being defined.
  def initialize(user)
    return unless user.present?

    # Users can read all songs (public catalog)
    can :read, Song
    can :create, Song
    can :update, Song
    can :destroy, Song

    # Users can only manage their own playlists
    can :manage, Playlist, user: user

    # Users can only manage songs in their own playlists
    can :create, PlaylistSong do |playlist_song|
      playlist_song.playlist.user == user
    end

    can :destroy, PlaylistSong do |playlist_song|
      playlist_song.playlist.user == user
    end

    # Users can only manage exports of their own playlists
    can :manage, Export do |export|
      export.playlist.user == user
    end
  end
end
