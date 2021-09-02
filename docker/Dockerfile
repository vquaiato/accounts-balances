FROM elixir

WORKDIR /accounts

ADD . /accounts

RUN tar -xzf accounts.tar.gz

EXPOSE 8080

CMD ["bin/accounts", "foreground"]