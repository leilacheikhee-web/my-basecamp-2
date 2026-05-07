FROM ruby:3.2

# Install system dependencies
RUN apt-get update -qq && apt-get install -y \
    build-essential \
    libpq-dev \
    nodejs

WORKDIR /app

# Copy Gemfile and install gems
COPY Gemfile ./
RUN bundle install

# Copy the rest of the code
COPY . .

# Ensure the uploads folder exists for your Volume
RUN mkdir -p public/uploads

EXPOSE 8080

# The command that was failing before
CMD ["bundle", "exec", "rackup", "--host", "0.0.0.0", "--port", "8080"]