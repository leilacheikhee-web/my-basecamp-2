FROM ruby:3.1

# Install system dependencies
RUN apt-get update -qq && apt-get install -y \
    build-essential \
    libpq-dev \
    postgresql-client \
    nodejs

WORKDIR /app

# Copy Gemfile and Gemfile.lock (if exists)
COPY Gemfile* ./
RUN bundle install

# Copy the rest of the code
COPY . .

# Create uploads directory and ensure it's writable
RUN mkdir -p public/uploads && chmod 755 public/uploads

EXPOSE 8080

# Set production environment
ENV RACK_ENV=production

# The app will use DATABASE_URL injected by Render
# Or use SQLite if running locally
CMD ["bundle", "exec", "rackup", "--host", "0.0.0.0", "--port", "8080"]