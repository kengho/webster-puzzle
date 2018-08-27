import React, { Component } from 'react';
import {
  BrowserRouter as Router,
  Route,
} from 'react-router-dom'
import GithubMark from 'react-github-mark';

import './App.css';
import Puzzle from './Puzzle';

class App extends Component {
  render() {
    let puzzlePath = '/:destination?/:steps*';
    if (process.env.REACT_APP_RELATIVE_URL_ROOT) {
      puzzlePath = `${process.env.REACT_APP_RELATIVE_URL_ROOT}${puzzlePath}`
    }
    return(
      <div>
        <Router>
          <div className="App">
            <Route path={puzzlePath} component={Puzzle} />
          </div>
        </Router>
        <GithubMark
          href="https://github.com/kengho/webster-puzzle"
          position="bottom-right"
        />
      </div>
    );
  }
}

export default App;
