require_relative "GZR_ini"

File.basename(__FILE__) =~ /(\d+)\.rb$/
@sot.test_nr = $1

###############################################################################

@sl.h1 'Verify wallet functions'

###

@sot.txt 'Set wallets'

@sot.own :set_wallet,            @wallet_account
@sot.own :set_redemption_wallet, @redemption_account
@sot.own :set_whitelist_wallet,  @whitelist_account

@sot.exp :wallet,            @sot.strip0x(@wallet_account)
@sot.exp :redemption_wallet, @sot.strip0x(@redemption_account)
@sot.exp :whitelist_wallet,  @sot.strip0x(@whitelist_account)

@sot.do


###############################################################################

@sl.h1 'Verify whitelist functions'

###

@sot.txt 'Add to whitelist'
@sot.add :add_to_whitelist, @whitelist_key, @a[1]
@sot.exp :whitelist, @a[1], true
@sot.do
 
###

@sot.txt 'Add to whitelist multiple'
(2..8).each do |i|
  @sot.exp :whitelist, @a[i], true
end
@sot.do_begin

@sot.contract @whitelist_key
@sot.contract.transact_and_wait.add_to_whitelist_multiple @a[2..8]
@sl.p "transact_and_wait.add_to_whitelist_multiple @a[2..8]"

@sot.do_end

 
###

@sot.txt 'Add to whitelist as owner (ok)'
@sot.own :add_to_whitelist, @a[10]
@sot.exp :whitelist, @a[10], true
@sot.do

###

@sot.txt 'Add to whitelist with other key (fail)'
@sot.add :add_to_whitelist, @k[4], @a[1]
@sot.exp :whitelist, @a[11], false
@sot.do


###############################################################################

@sl.h1 'Verify ICO date change function'

epoch = @sot.var :date_presale_start
jump_to(epoch, 'presale')

# uint public constant DATE_PRESALE_START = 1510318800; // 10-Nov-2017 13:00 UTC
# uint public constant DATE_PRESALE_END   = 1510923600; // 17-Nov-2017 13:00 UTC
# uint public dateIcoStart = 1511528400; // 24-Nov-2017 13:00 UTC
# uint public dateIcoEnd   = 1513947600; // 22-Dec-2017 13:00 UTC

# 1511528400 + 86400 = 1511614800
# 1513947600 + 86400 = 1514034000

###

@sot.txt 'Modify ICO dates - fail (not owner)'
@sot.add :update_ico_dates, @whitelist_key, 1511614800, 1514034000
@sot.exp :date_ico_start, nil, 0
@sot.exp :date_ico_end, nil, 0
@sot.do

###

@sot.txt 'Modify ICO dates - fail (end before start)'

@sot.add :update_ico_dates, @whitelist_key, 1514034000, 1511614800
@sot.exp :date_ico_start, nil, 0
@sot.exp :date_ico_end, nil, 0
@sot.do

###

@sot.txt 'Modify ICO dates - fail (start is before now)'
@sot.own :update_ico_dates, 1510318800, 1513947600
@sot.exp :date_ico_start, nil, 0
@sot.exp :date_ico_end, nil, 0
@sot.do

###

@sot.txt 'Modify ICO dates - ok (called by owner)'

@sot.own :update_ico_dates, 1511614800, 1514034000
@sot.exp :date_ico_start, nil, 86400
@sot.exp :date_ico_end, nil, 86400
@sot.do

###

epoch = @sot.var :date_ico_start
jump_to(epoch, 'ico')

@sot.txt 'Modify ICO dates - fail (ico already started)'
@sot.own :update_ico_dates, 1511614800 + 1000, 1514034000 + 1000
@sot.exp :date_ico_start, nil, 0
@sot.exp :date_ico_end, nil, 0
@sot.do

###############################################################################

@sot.dump
output_pp @sot.get_state(true), "state_#{@sot.test_nr}.txt"
