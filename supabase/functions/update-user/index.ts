import { createClient } from 'npm:@supabase/supabase-js@2.95.0'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

type UpdateUserRequest = {
  userId?: string
  username?: string
  password?: string
}

function usernameToEmail(username: string): string {
  const clean = username.trim().toLowerCase().replace(/[^a-z0-9._-]/g, '_')
  return `${clean}@nesting.local`
}

Deno.serve(async (request: Request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')
    const publishableKey = Deno.env.get('SUPABASE_ANON_KEY') ?? Deno.env.get('SUPABASE_PUBLISHABLE_KEY')
    const secretKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? Deno.env.get('SUPABASE_SECRET_KEY')
    const authorization = request.headers.get('Authorization')

    if (!supabaseUrl || !publishableKey || !secretKey || !authorization) {
      return new Response(JSON.stringify({ error: 'Server configuration or authorization is missing.' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const callerClient = createClient(supabaseUrl, publishableKey, {
      global: { headers: { Authorization: authorization } },
      auth: { persistSession: false },
    })

    const { data: authData, error: authError } = await callerClient.auth.getUser()
    if (authError || !authData.user) throw new Error('Invalid signed-in user.')

    const { data: callerProfile, error: profileError } = await callerClient
      .from('profiles')
      .select('role, is_active')
      .eq('id', authData.user.id)
      .single()

    if (profileError || callerProfile?.role !== 'admin' || callerProfile?.is_active !== true) {
      return new Response(JSON.stringify({ error: 'Admin access required.' }), {
        status: 403,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const body = (await request.json()) as UpdateUserRequest
    const userId = body.userId?.trim() ?? ''
    const username = body.username?.trim() ?? ''
    const password = body.password ?? ''

    if (!userId) throw new Error('User ID is required.')
    if (!username && !password) throw new Error('Provide a username or a password to update.')
    if (username && !/^[a-zA-Z0-9._-]+$/.test(username)) {
      throw new Error('Username may only contain letters, numbers, dots, underscores, and hyphens.')
    }
    if (password && password.length < 6) {
      throw new Error('Password must contain at least 6 characters.')
    }

    const adminClient = createClient(supabaseUrl, secretKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    })

    if (username) {
      const normalized = username.toLowerCase()
      const { data: duplicate } = await adminClient
        .from('profiles')
        .select('id')
        .eq('username', normalized)
        .neq('id', userId)
        .maybeSingle()
      if (duplicate) throw new Error('That username is already in use.')

      const { data: target, error: getError } = await adminClient.auth.admin.getUserById(userId)
      if (getError || !target.user) throw getError ?? new Error('User was not found.')

      const metadata = { ...(target.user.user_metadata ?? {}), username: normalized }
      const { error: authUpdateError } = await adminClient.auth.admin.updateUserById(userId, {
        email: usernameToEmail(normalized),
        email_confirm: true,
        user_metadata: metadata,
      })
      if (authUpdateError) throw authUpdateError

      const { error: profileUpdateError } = await adminClient
        .from('profiles')
        .update({ username: normalized })
        .eq('id', userId)
      if (profileUpdateError) throw profileUpdateError
    }

    if (password) {
      const { error: passwordError } = await adminClient.auth.admin.updateUserById(userId, { password })
      if (passwordError) throw passwordError
    }

    return new Response(JSON.stringify({ ok: true }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error'
    return new Response(JSON.stringify({ error: message }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
