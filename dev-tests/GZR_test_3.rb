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

(1..10).each do |i|
  @sot.add :add_to_whitelist, @whitelist_key, @a[i]
  @sot.exp :whitelist, @a[i], true
end

@sot.do
 

###############################################################################

@sl.h1 'Before presale'

###

@sot.txt 'Private sale contributions' # token rate 1150 per eth

@sot.own :private_sale_contribution, @a[1],   10 * @E18
@sot.own :private_sale_contribution, @a[11], 100 * @E18 # ok, whitelist does not apply
@sot.own :private_sale_contribution, @a[3], 1000 * @E18 # over the limit

@sot.exp :balance_of, @a[1],   11500 * @E6,  11500 * @E6
@sot.exp :balance_of, @a[11], 115000 * @E6, 115000 * @E6
@sot.exp :balance_of, @a[3],       0 * @E6,      0 * @E6

@sot.do

###

@sot.txt 'Some minting (ok) and an early contribution (throws)'

@sot.own :mint_reserve, @a[1], 100000 * @E6
@sot.own :mint_team,    @a[1],  50000 * @E6

@sot.snd @k[1], 10 # this contribution gets rejected

@sot.exp :balance_of, @a[1], 161500 * @E6, 150000 * @E6

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
@sot.exp :tokens_issued_total, 825250 * @E6, 200 * 1075 * @E6
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
@sot.snd @k[12], 100 # not on whitelist

@sot.exp :balance_of,  @a[6], nil,  100 * 1050 * @E6
@sot.exp :balance_of,  @a[7], nil,  200 * 1050 * @E6
@sot.exp :balance_of,  @a[8], nil,  300 * 1000 * @E6
@sot.exp :balance_of,  @a[9], 0, 0
@sot.exp :balance_of, @a[12], 0, 0
@sot.exp :tokens_issued_total, 1440250 * @E6, 615000 * @E6
@sot.exp :ico_contributor_count, 3, 3

@sot.do


###############################################################################

@sl.h1 'After ICO'

epoch = @sot.var :date_ico_end
jump_to(epoch, 'after ico')

###

@sot.txt 'Declaring ICO finished'
@sot.own :declare_ico_finished
@sot.exp :ico_finished, true
@sot.do

###

@sot.txt 'Transfer - fails (not tradeable)'
@sot.add :transfer, @k[1], @a[19], 100000 * @E6
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
@sot.add :transfer, @k[1], @a[19], 100000 * @E6 # ok
@sot.add :transfer, @k[1], @a[20], 90000 * @E6 # fails, some tokens are locked
@sot.exp :balance_of,  @a[1], nil, -100000 * @E6
@sot.exp :balance_of,  @a[19], 100000 * @E6, 100000 * @E6
@sot.exp :balance_of,  @a[20], 0, 0
@sot.do

###

@sot.txt 'Reclaim funds - not possible'
@sot.add :reclaim_funds, @k[1]
@sot.exp :balance_of, @a[1], nil, 0
@sot.exp :get_balance, @a[1], nil, 0
@sot.do

###############################################################################

@sl.h1 'After lockup end date'

epoch = @sot.var :lockup_end_date
jump_to(epoch, 'after lockup end')

###

@sot.txt 'Transfer - after lockup period ends (ok)'
@sot.add :transfer, @k[1], @a[20], 90000 * @E6
@sot.exp :balance_of,  @a[1], nil, -90000 * @E6
@sot.exp :balance_of,  @a[20], 90000 * @E6, 90000 * @E6
@sot.do

###############################################################################

@sot.dump
output_pp @sot.get_state(true), "state_#{@sot.test_nr}.txt"

