module Operations
  module Socket
    def init_socket
      @store = $window.storage(:sprintpoker)
      @auth_token = @store[:auth_token]
      @socket = Phoenix::Socket.new(SOCKET_URI, params: {auth_token: @auth_token})
      @socket.connect
    end

    def connect_to_lobby
      @channel.leave if @channel
      @channel = @socket.channel('lobby', {game_id: router.params[:game_id]})
      @channel.on 'auth_token' do |msg|
        @store[:auth_token] = @auth_token = msg[:auth_token]
      end
      @channel.on 'user' do |msg|
        @user = msg[:user]
        render!
      end
      @channel.on 'decks' do |msg|
        @decks = msg[:decks]
        render!
      end
      @channel.on 'game' do |msg|
        @game = msg[:game]
        router.go_to("/games/#{@game[:id]}")
        connect_to_game if in_game
      end
      @channel.join
    end

    def connect_to_game
      @channel.leave
      @channel = @socket.channel("game:#{router.params[:game_id]}")

      @channel.on 'state' do |msg|
        $console.log msg.inspect
        render!
      end

      @channel.on 'game' do |msg|
        $console.log msg.inspect
        @game = msg[:game]
        render!
      end

      @channel.join
    end
  end
end
