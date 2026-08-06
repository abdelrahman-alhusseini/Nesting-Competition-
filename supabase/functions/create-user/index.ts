import { createClient } from 'npm:@supabase/supabase-js@2.95.0'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

type CreateUserRequest = {
  username?: string
  password?: string
  displayName?: string
  role?: 'agent' | 'admin'
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
    if (authError || !authData.user) {
      throw new Error('Invalid signed-in user.')
    }

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

    const body = (await request.json()) as CreateUserRequest
    const username = body.username?.trim() ?? ''
    const password = body.password ?? ''
    const displayName = body.displayName?.trim() || username
    const role = body.role === 'admin' ? 'admin' : 'agent'

    if (!username || !/^[a-zA-Z0-9._-]+$/.test(username)) {
      throw new Error('Username may only contain letters, numbers, dots, underscores, and hyphens.')
    }
    if (password.length < 6) {
      throw new Error('Password must contain at least 6 characters.')
    }

    const adminClient = createClient(supabaseUrl, secretKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    })

    const { data: created, error: createError } = await adminClient.auth.admin.createUser({
      email: usernameToEmail(username),
      password,
      email_confirm: true,
      user_metadata: {
        username: username.toLowerCase(),
        display_name: displayName,
      },
    })

    if (createError || !created.user) {
      throw createError ?? new Error('User creation failed.')
    }

    const { error: updateError } = await adminClient
      .from('profiles')
      .update({
        display_name: displayName,
        role,
        is_active: true,
      })
      .eq('id', created.user.id)

    if (updateError) {
      await adminClient.auth.admin.deleteUser(created.user.id)
      throw updateError
    }

    return new Response(
      JSON.stringify({
        id: created.user.id,
        username: username.toLowerCase(),
        displayName,
        role,
      }),
      {
        status: 201,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      },
    )
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error'
    return new Response(JSON.stringify({ error: message }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
