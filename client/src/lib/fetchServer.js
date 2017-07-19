import getServerOrigin from './getServerOrigin';

const fetchServer = (relativeUrl) => {
  const serverOrigin = getServerOrigin();
  const headers = new Headers(); // eslint-disable-line no-undef
  headers.append('Content-Type', 'application/json');
  headers.append('Accept', 'application/json');

  // CORS for development setup.
  headers.append('Origin', window.location.origin); // eslint-disable-line no-undef

  const promise = fetch( // eslint-disable-line no-undef
    `${serverOrigin}${relativeUrl}`,
    {
      mode: 'cors',
      headers,
    },
  )
    .then((response) => response.json());

  return promise;
};

export default fetchServer;
