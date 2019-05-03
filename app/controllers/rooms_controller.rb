class RoomsController < ApplicationController

  def index

    @rooms = Room.all

    if params[:search].present?
      @rooms = @rooms.where(name: params[:search])
    end

    if params[:min_price].present? && params[:max_price].present?
      @rooms = @rooms.where(
        'price <= ? AND price >= ?',
        params[:max_price], params[:min_price]
      )
    end

    if params[:min_beds].present? && params[:max_beds].present?
      @rooms = @rooms.where(
        'amount_of_beds <= ? AND amount_of_beds >= ?',
        params[:max_beds], 
        params[:min_beds]
      )
    end

  end

  def show    
    @room = Room.find(params[:id])
    @conflict_ids = []
    @bookings = @room.bookings 
    @error = ''
  end


  def book 
    if params[:min_date].present? && params[:max_date].present?

      @room = Room.find(params[:id])
      @promotions = @room.promotions
      @bookings = @room.bookings

      @conflict_ids = @bookings.where(
        [
          '(start_date <= :min_date AND end_date >= :max_date)',
          '(start_date >= :min_date AND start_date <= :max_date)',
          '(end_date >= :min_date AND end_date <= :max_date)'
        ].join(' OR'),
        {
          min_date: params[:min_date],
          max_date: params[:max_date]
        }  
      ).ids

      
      if @conflict_ids.none?
        
        paid_price = @room.price

        if @promotions.any? 

          @promotions.each do |promotion|
            if promotion.start_date <= Date.today && promotion.end_date >= Date.today
              if promotion.discount_type == 'percentage'
                paid_price = ((1 - promotion.discount_amount.to_f/100)*paid_price).to_i
              elsif promotion.discount_type == 'fixed'
                paid_price = paid_price - promotion.discount_amount
              end
            end
          end

        end

        paid_price = 0 if paid_price < 0

        current_user.bookings.create( 
          start_date: params[:min_date], 
          end_date: params[:max_date], 
          paid_price: paid_price, 
          room_id: @room.id 
        )            
      end
      redirect_to action: 'show'
    end  
  end
end
