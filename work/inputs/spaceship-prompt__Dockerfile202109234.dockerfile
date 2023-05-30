FROM frapsoft/zsh

# Configurable user
ARG USERNAME=spaceship

# Setting up a user
RUN adduser -D -s /bin/zsh $USERNAME
USER $USERNAME
WORKDIR /home/$USERNAME

# Coppying Spaceship to the image
COPY . spaceship

# Setting up .zshrc
RUN echo "export TERM=xterm-256color" >> /home/$USERNAME/.zshrc
RUN echo "source spaceship/spaceship.zsh" >> /home/$USERNAME/.zshrc

# zsh as an entrypoint
ENTRYPOINT ["/bin/zsh"]
