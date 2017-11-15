require_relative "GZR_ini"

File.basename(__FILE__) =~ /(\d+)\.rb$/
@sot.test_nr = $1

###############################################################################

@sl.h1 'Preliminary actions'

###

@sot.txt 'Set wallets'

@sot.own :set_wallet,            @wallet_account
@sot.own :set_redemption_wallet, @redemption_account
@sot.own :set_whitelist_wallet,  @whitelist_account

@sot.exp :wallet,            @sot.strip0x(@wallet_account)
@sot.exp :redemption_wallet, @sot.strip0x(@redemption_account)
@sot.exp :whitelist_wallet,  @sot.strip0x(@whitelist_account)

@sot.do

###

@sot.txt 'Add accounts 1-10 to whitelist'

(2..10).each do |i|
  @sot.add :add_to_whitelist, @whitelist_key, @a[i]
  @sot.exp :whitelist, @a[i], true
end

@sot.do
 

###############################################################################

@sl.h1 'Before presale'

###

@sot.txt 'Private sale contributions' # token rate 1150 per eth

@sot.own :private_sale_contribution, @a[1],   10 * @E18 # ok
@sot.own :private_sale_contribution, @a[11], 100 * @E18 # ok
@sot.own :private_sale_contribution, @a[3], 1000 * @E18 # over the limit

@sot.exp :balance_of, @a[1],   11500 * @E6,  11500 * @E6
@sot.exp :balance_of, @a[11], 115000 * @E6, 115000 * @E6
@sot.exp :balance_of, @a[3],       0 * @E6,      0 * @E6

@sot.do

###

@sot.txt 'Some minting (ok) and an early contribution (throws)'

@sot.own :mint_reserve, @a[1], 100000 * @E6
@sot.own :mint_team,    @a[1],  50000 * @E6

@sot.own :mint_reserve, @a[2],  10000 * @E6
@sot.own :mint_team,    @a[2],   5000 * @E6

@sot.snd @k[1], 10 # this contribution gets rejected

@sot.exp :balance_of, @a[1], 161500 * @E6, 150000 * @E6
@sot.exp :balance_of, @a[2], nil, 15000 * @E6

@sot.do


###############################################################################

@sl.h1 'Presale'

epoch = @sot.var :date_presale_start
jump_to(epoch, 'presale')

###

@sot.txt 'Some presale contributions'

@sot.snd @k[1], 25
@sot.snd @k[2], 50
@sot.snd @k[3], 75
@sot.snd @k[4], 150
@sot.snd @k[5], 0.005 # too little

@sot.exp :balance_of, @a[1], nil,  25 * 1150 * @E6
@sot.exp :balance_of, @a[2], nil,  50 * 1150 * @E6
@sot.exp :balance_of, @a[3], nil,  75 * 1100 * @E6
@sot.exp :balance_of, @a[4], nil, 150 * 1100 * @E6
@sot.exp :balance_of, @a[5], 0, 0
@sot.exp :get_balance, @contract_address, 300 * @E18, 300 * @E18
@sot.exp :presale_contributor_count, 4, 4

@sot.do

###

@sot.txt 'Presale contribution taking us above the funding threshold'

@sot.snd @k[5], 200
@sot.snd @k[6], 3000 # over the funding cap

@sot.exp :balance_of, @a[5], nil,  200 * 1075 * @E6
@sot.exp :balance_of, @a[6], 0,  0
@sot.exp :get_balance, @contract_address, 0, -300 * @E18
@sot.exp :get_balance, @wallet_account, nil, 500 * @E18
@sot.exp :tokens_issued_total, 840250 * @E6, 200 * 1075 * @E6
@sot.exp :presale_contributor_count, 5, 1

@sot.do


###############################################################################

@sl.h1 'After presale'

epoch = @sot.var :date_presale_end
jump_to(epoch, 'after presale')

###

@sot.txt 'No more contributions accepted after presale end'
@sot.snd @k[6], 100
@sot.exp :balance_of, @a[6], 0,  0
@sot.do


###############################################################################

@sl.h1 'ICO'

epoch = @sot.var :date_ico_start
jump_to(epoch, 'ico')

###

@sot.txt 'ICO contributions'

@sot.snd @k[6], 100
@sot.snd @k[7], 200
@sot.snd @k[8], 300
@sot.snd @k[9], 3334 # too much

@sot.exp :balance_of,  @a[6], nil,  100 * 1050 * @E6
@sot.exp :balance_of,  @a[7], nil,  200 * 1050 * @E6
@sot.exp :balance_of,  @a[8], nil,  300 * 1000 * @E6
@sot.exp :balance_of,  @a[9], 0, 0
@sot.exp :tokens_issued_total, 1455250 * @E6, 615000 * @E6
@sot.exp :ico_contributor_count, 3, 3

@sot.do

###

@sot.txt 'ICO - approaching 70 million tokens'
22.times do
  @sot.snd @k[12], 3000
end
@sot.snd @k[12], 2700
@sot.exp :tokens_issued_crowd, 69990250 * @E6, nil
@sot.do

###############################################################################

@sl.h1 'ICO declared finished'

###
@sot.txt 'Declare ICO finished (ok)'
@sot.own :declare_ico_finished
@sot.exp :ico_finished, true
@sot.do

# check lockupEndDate (should be 180 days)
e1 = @sot.var :date_ico_start
e2 = @sot.var :lockup_end_date
diff = e2 - e1
@sl.p "lockup_end_date - date_ico_start = #{diff} (#{diff/(24*3600)} days)"

###

@sot.txt 'Transfer - fails (not tradeable)'
@sot.add :transfer, @k[1], @a[19], 1 * @E6
@sot.exp :balance_of,  @a[1], nil, 0
@sot.exp :balance_of,  @a[19], 0, 0
@sot.do

###

@sot.txt 'Make tradeable'
@sot.own :make_tradeable
@sot.exp :tradeable, true
@sot.do

###

@sot.txt 'Transfer'
@sot.add :transfer, @k[1], @a[19],  111500 * @E6 # ok
@sot.add :transfer, @k[1], @a[20],       1 * @E6 # fails, remaining tokens
@sot.exp :balance_of,  @a[1], 78750 * @E6, -111500 * @E6
@sot.exp :locked_balance, @a[1], 78750 * @E6, nil
@sot.exp :balance_of,  @a[19],      111500 * @E6, 111500 * @E6
@sot.exp :balance_of,  @a[20], 0, 0
@sot.do

###

@sot.txt 'Reclaim funds - not possible'
@sot.add :reclaim_funds, @k[1]
@sot.exp :balance_of, @a[1], nil, 0
@sot.exp :get_balance, @a[1], nil, 0
@sot.do

###

@sot.txt 'Owner tries to retrieve forfeited tokens (too early)'
@sot.own :retrieve_forfeited_tokens, @a[1]
@sot.exp :balance_of, @a[1], nil, 0
@sot.exp :balance_of, @wallet_account, nil, 0
@sot.do

###############################################################################

@sl.h1 'After FORFEIT_PERIOD'

epoch = @sot.var :date_ico_end
jump_to(epoch  + 30*24*3600 + 100, 'after forfeit period')

@sot.txt 'Owner tries to retrieve forfeited tokens (ok)'
@sot.own :retrieve_forfeited_tokens, @a[1]
@sot.exp :balance_of, @a[1], nil, -28750 * @E6
@sot.exp :balance_of, @wallet_account, nil, 28750 * @E6
@sot.exp :locked_balance, @a[1], 50000 * @E6, nil
@sot.do

###############################################################################

@sl.h1 'After lockup end date'

epoch = @sot.var :lockup_end_date
jump_to(epoch, 'after lockup end')

###

@sot.txt 'Transfer - after lockup period ends (ok)'
@sot.add :transfer, @k[1], @a[20], 50000 * @E6
@sot.exp :balance_of,  @a[1], 0, -50000 * @E6
@sot.exp :balance_of,  @a[20], 50000 * @E6, 50000 * @E6
@sot.do

###############################################################################

@sot.dump
output_pp @sot.get_state(true), "state_#{@sot.test_nr}.txt"

