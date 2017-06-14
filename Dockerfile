FROM ruby:2.3.0

RUN apt-get update && rm -rf /var/lib/apt/lists/*
WORKDIR /app

COPY Gemfile /app
RUN bundle install

COPY . /app

# 150秒に一回
CMD ["watch", "-n", "60", "ruby", "kari.rb"]