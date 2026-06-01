const { createClient } = require('@supabase/supabase-js');
const jwt = require('jsonwebtoken');

const supabaseUrl = 'https://xbpwsdpswcxhogzaalqn.supabase.co';
const supabaseKey = 'sb_publishable_R_8ep0PEq7BerXCGbeG68Q_223uP3Ox';
const supabase = createClient(supabaseUrl, supabaseKey);

async function test() {
  const { data, error } = await supabase.auth.signInWithPassword({
    email: 'fady@gmail.com',
    password: 'asdASD123@@@'
  });

  if (error) {
    console.error('Login failed:', error.message);
    return;
  }

  const session = data.session;
  console.log('Session Keys:', Object.keys(session));
  console.log('Session User Keys:', Object.keys(session.user));
  console.log('Session.user.id:', session.user.id);
  
  const decoded = jwt.decode(session.access_token);
  console.log('Full Decoded JWT Payload:', JSON.stringify(decoded, null, 2));
  
  console.log('session_id in JWT:', decoded.session_id);
}

test();
