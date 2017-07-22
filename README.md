# Webster Puzzle

## Summary

[Rails](http://rubyonrails.org/)-[react](https://facebook.github.io/react/)-powered dictionary puzzle game, where the goal is to find a chain of definitions that leads from one given word to other.

This app takes advantages from using [Javier Julio's GCIDE dictionary parser](https://github.com/javierjulio/dictionary).

This project was bootstrapped with [Create React App](https://github.com/facebookincubator/create-react-app).

![main view](/doc/img/main.png?raw=true)

## Live

[https://kengho.tech/webster-puzzle](https://kengho.tech/webster-puzzle)

## Installing

### Development

#### Prepare app

```
git clone https://github.com/kengho/webster-puzzle webster
cd webster
bundle install
npm insall
cp .env.example .env
nano .env
# setup these variables # VARIABLE1=value1\n...
# SECRET_KEY_BASE,
# DB_USERNAME,
# DB_PASSWORD,
# DB_HOST # default 'localhost'
# DB_PORT # default '5432'
# REACT_APP_SERVER_PORT # default '3000'
```

#### Prepare dictionary

```
cd ..
git clone https://github.com/javierjulio/dictionary dictionary
cd dictionary
ruby parse.rb
cd ..
cp dictionary/dictionary.json webster/app/lib/dictionary/dictionary.json
rake dictionary:prepare_json
```

#### Prepare db

```
sudo -u postgres psql
CREATE ROLE YOUR_DB_USERNAME WITH CREATEDB SUPERUSER LOGIN PASSWORD 'YOUR_DB_PASSWORD';
\q
rake db:setup
RAILS_ENV=development rake dictionary:prepare[1] # 1 is percents of dictionary keys to keep
RAILS_ENV=development rake puzzles:populate[100] # 100 is the number of puzzles
```

#### Run

```
foreman start -f Procfile.dev
```

http://localhost:5000 should display landing page.

### Production

<!---
TODO: move kengho.tech instructions out of here and spreadsheet.
--->

[kengho.tech webster-puzzle deploy instructions](https://gist.github.com/kengho/1c075f1459a571a5ac93510f83afdd2e) (Puma + Nginx).

## License

Webster Puzzle is distributed under the MIT-LICENSE.
